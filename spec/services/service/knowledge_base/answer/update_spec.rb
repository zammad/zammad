# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::KnowledgeBase::Answer::Update do
  subject(:update_answer) do
    described_class.with_current_user(user).execute(answer:, answer_data:, kb_locale:)
  end

  include_context 'basic Knowledge Base'

  let(:editor_role) { create(:role, permission_names: 'knowledge_base.editor') }
  let(:user)        { create(:user, roles: [editor_role]) }
  let(:kb_locale)   { primary_locale }

  let(:answer) do
    create(:knowledge_base_answer, category:, translation_attributes: { title: 'Stored title', kb_locale: primary_locale })
  end

  # Every attribute is optional, so the empty hash is the honest starting point: each case adds what
  #   it is about, and everything it leaves out has to stay as it is.
  let(:answer_data) { {} }

  before { answer }

  describe 'title and body' do
    let(:answer_data) { { title: 'New title', body: '<p>New body</p>' } }

    it 'writes them into the translation of the given locale', :aggregate_failures do
      translation = update_answer.translations.sole

      expect(translation.kb_locale).to eq(primary_locale)
      expect(translation.title).to eq('New title')
      expect(translation.content.body).to eq('<p>New body</p>')
    end

    context 'with only a body' do
      let(:answer_data) { { body: '<p>New body</p>' } }

      it 'keeps the stored title', :aggregate_failures do
        expect(update_answer.translations.sole.title).to eq('Stored title')
        expect(update_answer.translations.sole.content.body).to eq('<p>New body</p>')
      end
    end

    context 'with only a title' do
      let(:answer_data) { { title: 'New title' } }

      it 'keeps the stored body', :aggregate_failures do
        stored_body = answer.translations.sole.content.body

        expect(update_answer.translations.sole.title).to eq('New title')
        expect(update_answer.translations.sole.content.body).to eq(stored_body)
      end
    end

    # The one path a create never walks: an answer may well have no translation in the locale being
    #   edited yet, which is what the client shows as `translationMissing`.
    context 'with a locale the answer has no translation in' do
      let(:kb_locale) { alternative_locale }

      it 'adds one, and leaves the other locale alone', :aggregate_failures do
        expect(update_answer.translations.count).to eq(2)
        expect(update_answer.translation_to(alternative_locale)).to have_attributes(title: 'New title')
        expect(update_answer.translation_to(alternative_locale).content.body).to eq('<p>New body</p>')
        expect(update_answer.translation_to(primary_locale).title).to eq('Stored title')
      end

      # A translation does not validate without a content record, so the new one gets an empty
      #   body rather than none at all.
      context 'with only a title' do
        let(:answer_data) { { title: 'New title' } }

        it 'adds it with an empty body' do
          expect(update_answer.translation_to(alternative_locale).content.body).to eq('')
        end
      end

      # There is no stored title to keep here, and a translation without one does not validate -
      #   with an error the form could not even be shown, since rendering it reads `translations.
      #   title` off the answer.
      context 'with only a body' do
        let(:answer_data) { { body: '<p>New body</p>' } }

        it 'is rejected', :aggregate_failures do
          expect { update_answer }.to raise_error(Exceptions::UnprocessableContent, %r{A title is required})
          expect(answer.reload.translations.count).to eq(1)
        end
      end
    end

    context 'with a title another answer of the same category already uses' do
      let(:answer_data) { { title: 'Taken title' } }

      before do
        create(:knowledge_base_answer, category:, translation_attributes: { title: 'Taken title', kb_locale: primary_locale })
      end

      # Reported on the answer's `translations.title` path, which is what the form maps back onto
      #   its own field.
      it 'raises a validation error', :aggregate_failures do
        expect { update_answer }.to raise_error(ActiveRecord::RecordInvalid) do |error|
          expect(error.record.errors.attribute_names).to include(:'translations.title')
        end
      end
    end

    # Titles are unique among the siblings *of one locale*: KnowledgeBase::HasUniqueTitle scopes by
    #   `kb_locale_id`.
    context 'with a title another answer of the same category uses in another locale' do
      let(:answer_data) { { title: 'Taken title' } }

      before do
        create(:knowledge_base_answer, category:,
                                       translation_attributes: { title: 'Taken title', kb_locale: alternative_locale })
      end

      it 'is accepted' do
        expect(update_answer.translations.sole.title).to eq('Taken title')
      end
    end

  end

  describe 'the category' do
    let(:answer_data) { { category: other_category } }

    it 'moves the answer' do
      expect(update_answer.category).to eq(other_category)
    end

    context 'when it is the stored one' do
      let(:answer_data) { { category: category } }

      it 'leaves the answer where it is' do
        expect(update_answer.category).to eq(category)
      end
    end

    context 'when it is not submitted' do
      let(:answer_data) { { title: 'New title' } }

      it 'leaves the answer where it is' do
        expect(update_answer.category).to eq(category)
      end
    end

    context 'when it belongs to another knowledge base' do
      let(:answer_data) { { category: create(:knowledge_base_category) } }

      it 'refuses the move', :aggregate_failures do
        expect { update_answer }.to raise_error(Exceptions::UnprocessableContent, %r{does not belong to this knowledge base})
        expect(answer.reload.category).to eq(category)
      end
    end
  end

  # Editor access to the answer itself is not asked by the service - the mutation's `answer_id`
  #   argument gates it, and its spec covers that. Where the answer may be *filed* is a question no
  #   argument gate sees, and it is this service's own.
  describe 'authorization' do
    context 'with a granular editor of one subtree' do
      let(:granular_role) { create(:role, permission_names: 'knowledge_base.editor') }
      let(:user)          { create(:user, roles: [granular_role]) }

      before do
        create(:knowledge_base_permission, permissionable: knowledge_base, role: granular_role, access: 'reader')
        create(:knowledge_base_permission, permissionable: category, role: granular_role, access: 'editor')
      end

      it 'updates an answer in the permitted category' do
        expect(update_answer.category).to eq(category)
      end

      # Editing where the answer is and filing it somewhere else are two questions - the first one is
      #   the argument gate's, the second one is asked here.
      context 'when moving it into a category they only read' do
        let(:answer_data) { { category: other_category } }

        it 'refuses the move', :aggregate_failures do
          expect { update_answer }.to raise_error(Pundit::NotAuthorizedError)
          expect(answer.reload.category).to eq(category)
        end
      end
    end
  end

  describe 'visibility' do
    let(:answer_data) { { visibility: state } }

    # The answer of this section starts out in the state its context names, so every example has a
    #   definite from-state.
    let(:answer) { create(:knowledge_base_answer, from, category:, translation_attributes: { kb_locale: primary_locale }) }
    let(:from)   { :draft }

    # Re-read rather than asked of the returned record: the state is derived by a state machine the
    #   record memoizes, so an instance that was around before the change could answer from it.
    def visibility_after_update
      update_answer

      KnowledgeBase::Answer.find(answer.id).visibility
    end

    # All sixteen combinations, the four that change nothing included - the state is derived from
    #   the timestamps, so reaching one means writing its own and clearing whatever would win over
    #   it, in both directions.
    %i[draft internal published archived].each do |from_state|
      %i[draft internal published archived].each do |to_state|
        context "when a #{from_state} answer is set to #{to_state}" do
          let(:from)  { from_state }
          let(:state) { to_state }

          it "leaves the answer #{to_state}" do
            expect(visibility_after_update).to eq(to_state)
          end
        end
      end
    end

    context 'when the answer is published' do
      let(:from) { :published }

      # The form sends the stored state back on every round trip, so writing the timestamp again
      #   would creep the publication date - and its `published_by` - forward on every edit.
      context 'when it stays published' do
        let(:state) { :published }

        it 'keeps the date it was published at' do
          expect { update_answer }.not_to change { answer.reload.published_at }
        end
      end

      context 'when it goes back to draft' do
        let(:state) { :draft }

        it 'clears every publication timestamp' do
          expect(update_answer).to have_attributes(internal_at: nil, published_at: nil, archived_at: nil)
        end
      end

      context 'when it is archived' do
        let(:state) { :archived }

        # How it got there is worth keeping: the reader view shows both dates.
        it 'keeps the date it was published at', :aggregate_failures do
          expect(update_answer.archived_at).to be_within(2.minutes).of(Time.current)
          expect(update_answer.published_at).to be_present
        end
      end
    end

    context 'when the answer is internal' do
      let(:from) { :internal }

      context 'when it is published' do
        let(:state) { :published }

        it 'keeps the date it went internal at', :aggregate_failures do
          expect(update_answer.published_at).to be_within(2.minutes).of(Time.current)
          expect(update_answer.internal_at).to be_present
        end
      end

      # The publication would otherwise be refused by CanBePublished#published_after_internal - and
      #   a schedule that is superseded before it is reached never happened.
      context 'when publishing it now supersedes its future internal date' do
        let(:answer) { create(:knowledge_base_answer, category:, internal_at: 1.week.from_now, translation_attributes: { kb_locale: primary_locale }) }
        let(:state)  { :published }

        it 'drops the scheduled internal date', :aggregate_failures do
          expect(update_answer.internal_at).to be_nil
          expect(visibility_after_update).to eq(:published)
        end
      end
    end

    # A submitted state is always the one in effect from now on, so setting the very state a
    #   schedule was going to reach is what cancels that schedule.
    context 'when the answer is scheduled to go internal' do
      let(:answer) { create(:knowledge_base_answer, category:, internal_at: 1.week.from_now, translation_attributes: { kb_locale: primary_locale }) }
      let(:state)  { :internal }

      it 'publishes it internally right away', :aggregate_failures do
        expect(update_answer.internal_at).to be_within(2.minutes).of(Time.current)
        expect(visibility_after_update).to eq(:internal)
      end
    end

    # A schedule ranks above whatever is in effect now - it could not take effect otherwise - so the
    #   branch that clears the states outranking the target one would clear it on every save. But an
    #   ordinary save only ever says what the answer's state is *at the moment*: cancelling a
    #   transition the old interface scheduled is that schedule's own business, not a side effect of
    #   fixing a typo.
    context 'when a transition is scheduled for later' do
      let(:scheduled) { 1.week.from_now.change(sec: 0) }

      context 'when the answer is saved as the draft it still is' do
        let(:answer) do
          create(:knowledge_base_answer, category:, published_at: scheduled,
                                         translation_attributes: { kb_locale: primary_locale })
        end
        let(:state) { :draft }

        it 'keeps the scheduled publication', :aggregate_failures do
          expect(update_answer.published_at).to be_within(1.second).of(scheduled)
          expect(visibility_after_update).to eq(:draft)
        end
      end

      # The same for a schedule that outranks a state which *is* already in effect.
      context 'when a published answer is scheduled to be archived' do
        let(:answer) do
          create(:knowledge_base_answer, :published, category:, archived_at: scheduled,
                                         translation_attributes: { kb_locale: primary_locale })
        end
        let(:state) { :published }

        it 'keeps the scheduled archival', :aggregate_failures do
          expect(update_answer.archived_at).to be_within(1.second).of(scheduled)
          expect(visibility_after_update).to eq(:published)
        end
      end
    end

    context 'when no visibility is submitted' do
      let(:answer)      { create(:knowledge_base_answer, :published, category:, translation_attributes: { kb_locale: primary_locale }) }
      let(:answer_data) { { title: 'New title' } }

      it 'leaves the publication state alone', :aggregate_failures do
        expect { update_answer }.not_to change { answer.reload.published_at }
        expect(visibility_after_update).to eq(:published)
      end
    end

    context 'with a state the answer knows nothing about' do
      let(:state) { :somewhat_public }

      it 'is a programming error' do
        expect { update_answer }.to raise_error(ArgumentError, %r{Unknown publication state})
      end
    end
  end

  # An existing answer's tags never travel through this service: they are written straight onto the
  #   record from the answer's sidebar (`tagAssignmentAdd`/`tagAssignmentRemove`), the same as the
  #   ticket detail view does - so the update input carries none, and nothing here can clear them.
  describe 'tags' do
    let(:answer_data) { { title: 'New title' } }

    before { answer.tag_add('first', user.id) }

    it 'leaves the stored tags alone' do
      expect(update_answer.tag_list).to contain_exactly('first')
    end
  end

  describe 'attachments' do
    let(:form_id)     { SecureRandom.uuid }
    let(:answer_data) { { form_id: form_id } }
    let(:answer)      { create(:knowledge_base_answer, :with_attachment, category:, translation_attributes: { kb_locale: primary_locale }) }

    # As the answering user: an upload cache is scoped to the user that filled it.
    before do
      UserInfo.with_user_id(user.id) do
        UploadCache.new(form_id).add(filename: 'attached.txt', data: 'attached', preferences: { 'Content-Type' => 'text/plain' })
      end
    end

    # The cache is what the answer ends up with, the files it had included - which is why the tab has
    #   to seed it with them when it opens.
    it 'replaces the answer files with the ones in the upload cache of the form' do
      expect(update_answer.reload.attachments.map(&:filename)).to eq(['attached.txt'])
    end

    # Unlike a create: the tab the answer was submitted from stays open, and its next save reads the
    #   same cache again.
    it 'leaves the upload cache alone' do
      update_answer

      expect(UploadCache.new(form_id).attachments(created_by_id: user.id)).not_to be_empty
    end

    context 'without a form' do
      let(:answer_data) { { title: 'New title' } }

      it 'leaves the answer files alone' do
        expect(update_answer.reload.attachments).not_to be_empty
      end
    end
  end

  # Only an active knowledge base is editable - the legacy admin dialog is what activates it.
  context 'when the knowledge base is inactive' do
    before { knowledge_base.update!(active: false) }

    it 'is rejected' do
      expect { update_answer }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context 'without a current user' do
    it 'is rejected' do
      expect { described_class.execute(answer:, answer_data:, kb_locale:) }
        .to raise_error(%r{Current user is required})
    end
  end
end
