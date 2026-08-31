# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::KnowledgeBase::Answer::Create do
  subject(:create_answer) do
    described_class.with_current_user(user).execute(answer_data:, kb_locale:)
  end

  include_context 'basic Knowledge Base'

  let(:editor_role) { create(:role, permission_names: 'knowledge_base.editor') }
  let(:user)        { create(:user, roles: [editor_role]) }
  let(:kb_locale)   { primary_locale }

  let(:title)      { 'Fresh answer' }
  let(:body)       { '<p>Fresh body</p>' }
  let(:tags)       { [] }
  let(:visibility) { :draft }

  # Everything the input type requires — the service takes it as given, so every case starts out
  #   with it and overrides what it is about. Only the form id is genuinely optional.
  let(:answer_data) { { category: category, title: title, body: body, tags: tags, visibility: visibility } }

  # The service resolves the single knowledge base itself, so it has to exist before the call — the
  #   shared context creates it lazily, and a category of another knowledge base must not be the
  #   only one around.
  before { knowledge_base }

  describe 'the created answer' do
    it 'files it in the given category, as a draft', :aggregate_failures do
      expect(create_answer).to be_persisted
      expect(create_answer.category).to eq(category)
      expect(create_answer.visibility).to eq(:draft)
    end

    it 'writes title and body into the translation of the given locale', :aggregate_failures do
      translation = create_answer.translations.sole

      expect(translation.kb_locale).to eq(kb_locale)
      expect(translation.title).to eq(title)
      expect(translation.content.body).to eq(body)
    end

    context 'with an alternative locale' do
      let(:kb_locale) { alternative_locale }

      it 'writes the translation into that locale' do
        expect(create_answer.translations.sole.kb_locale).to eq(alternative_locale)
      end
    end

    # The GraphQL layer hands over what the client sent rather than resolving the record itself.
    context 'with a system locale code instead of a locale record' do
      let(:kb_locale) { alternative_locale.system_locale.locale }

      before { alternative_locale }

      it 'writes the translation into that locale' do
        expect(create_answer.translations.sole.kb_locale).to eq(alternative_locale)
      end

      context 'when the knowledge base does not have that locale' do
        let(:kb_locale) { 'zh-cn' }

        it 'is rejected' do
          expect { create_answer }
            .to raise_error(Exceptions::UnprocessableContent, 'The selected language does not belong to this knowledge base.')
        end
      end
    end

    context 'with a title another answer of the same category already uses' do
      let(:title) { draft_answer.translation_primary.title }

      before { draft_answer }

      it 'raises a validation error' do
        expect { create_answer }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end

  describe 'the category' do
    context 'when it belongs to another knowledge base' do
      let(:answer_data) { super().merge(category: create(:knowledge_base_category)) }

      it 'refuses the answer' do
        expect { create_answer }.to raise_error(Exceptions::UnprocessableContent, 'The selected category does not belong to this knowledge base.')
      end
    end
  end

  describe 'authorization' do
    context 'with a granular editor of one subtree' do
      # Reader on the knowledge base plus editor on one category — the only constructible granular
      #   setup, since KnowledgeBase::PermissionsUpdate lets a child override a 'reader' parent only.
      before do
        create(:knowledge_base_permission, permissionable: knowledge_base, role: editor_role, access: 'reader')
        create(:knowledge_base_permission, permissionable: category, role: editor_role, access: 'editor')
      end

      it 'creates the answer in the permitted category' do
        expect(create_answer).to be_persisted
      end

      context 'when the category is only readable for them' do
        let(:answer_data) { super().merge(category: other_category) }

        it 'refuses the answer' do
          expect { create_answer }.to raise_error(Pundit::NotAuthorizedError)
        end

        it 'creates no answer' do
          expect { create_answer }.to raise_error(Pundit::NotAuthorizedError)
            .and(not_change(KnowledgeBase::Answer, :count))
        end
      end
    end
  end

  describe 'visibility' do
    let(:visibility) { state }

    let(:state) { :draft }

    # The timestamp per state is mapped rather than derived from its name, so a state the schema
    #   offers but the map does not know would only surface when someone picks it.
    it 'maps every state the schema offers, except the one that stores no timestamp' do
      expect(CanBePublished::SCHEDULABLE_VISIBILITIES.keys)
        .to match_array(Gql::Types::Enum::KnowledgeBase::VisibilityType.values.values.map(&:value) - [:draft])
    end

    context 'when it is draft' do
      it 'leaves every publication timestamp unset', :aggregate_failures do
        expect(create_answer).to have_attributes(internal_at: nil, published_at: nil, archived_at: nil)
        expect(create_answer.visibility).to eq(:draft)
      end
    end

    context 'when it is internal' do
      let(:state) { :internal }

      it 'publishes it internally right away', :aggregate_failures do
        expect(create_answer.internal_at).to be_present
        expect(create_answer.visibility).to eq(:internal)
      end
    end

    context 'when it is published' do
      let(:state) { :published }

      it 'publishes it right away', :aggregate_failures do
        expect(create_answer.published_at).to be_present
        expect(create_answer.visibility).to eq(:published)
      end
    end

    # Offered while creating, as agreed for the create form: the state is derived from the
    #   timestamps, so an `archived_at` on its own is a coherent archived answer.
    context 'when it is archived' do
      let(:state) { :archived }

      it 'archives it right away', :aggregate_failures do
        answer = create_answer

        expect(answer.archived_at).to be_present
        expect(answer).to have_attributes(internal_at: nil, published_at: nil)
        expect(answer.visibility).to eq(:archived)
      end
    end
  end

  describe 'tags' do
    let(:tags) { %w[first second] }

    it 'assigns them to the answer' do
      expect(create_answer.tag_list).to contain_exactly('first', 'second')
    end

    context 'when creating new tags is not allowed' do
      before do
        Tag::Item.lookup_by_name_and_create('first')
        Setting.set('tag_new', false)
      end

      it 'assigns the existing ones and skips the rest' do
        expect(create_answer.tag_list).to contain_exactly('first')
      end
    end
  end

  describe 'attachments' do
    let(:form_id)     { SecureRandom.uuid }
    let(:answer_data) { super().merge(form_id: form_id) }

    # As the answering user: an upload cache is scoped to the user that filled it, so files stored
    #   under anyone else are none of this service's business.
    before do
      UserInfo.with_user_id(user.id) do
        UploadCache.new(form_id).tap do |cache|
          cache.add(filename: 'attached.txt', data: 'attached', preferences: { 'Content-Type' => 'text/plain' })
          cache.add(filename: 'inline.png', data: 'inline', preferences: { 'Content-Type' => 'image/png', 'Content-Disposition' => 'inline' })
        end
      end
    end

    # Without the inline ones: those belong to the body, which carries its own images and has them
    #   pulled out into attachments of the translation content.
    it 'takes them out of the upload cache of the form' do
      expect(create_answer.attachments.map(&:filename)).to eq(['attached.txt'])
    end

    # Not left to the taskbar the client deletes afterwards: a client that keeps the tab around
    #   would leave them behind for the cleanup job to find.
    it 'empties the upload cache' do
      create_answer

      expect(UploadCache.new(form_id).attachments(created_by_id: user.id)).to be_empty
    end

    # The answer is committed before the cache is emptied, and another session closing the draft
    #   tab empties the same cache (Taskbar::HasAttachments) - so losing that race must not report
    #   the answer as failed, or a client retrying would file it a second time.
    context 'when the cache cannot be emptied' do
      before { allow(Store).to receive(:remove_item).and_raise(ActiveRecord::RecordNotFound) }

      it 'keeps the answer and its attachments', :aggregate_failures do
        answer = nil

        expect { answer = create_answer }.to change(KnowledgeBase::Answer, :count).by(1)
        expect(answer.attachments.map(&:filename)).to eq(['attached.txt'])

        # Without this the example would pass just as well for a cleanup that never runs, and
        #   with it for one that no longer fails the way this covers.
        expect(Store).to have_received(:remove_item)
      end
    end

    context 'without a form' do
      let(:answer_data) { super().except(:form_id) }

      it 'attaches nothing, and leaves the cache alone', :aggregate_failures do
        expect(create_answer.attachments).to be_empty
        expect(UploadCache.new(form_id).attachments(created_by_id: user.id)).not_to be_empty
      end
    end
  end

  # Only an active knowledge base is editable — the legacy admin dialog is what activates it.
  context 'when the knowledge base is inactive' do
    before { knowledge_base.update!(active: false) }

    it 'is rejected' do
      expect { create_answer }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context 'without a current user' do
    it 'is rejected' do
      expect { described_class.execute(answer_data:, kb_locale:) }
        .to raise_error(%r{Current user is required})
    end
  end
end
