# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe(FormUpdater::Updater::KnowledgeBase::Answer::Edit) do
  subject(:updater) do
    described_class.new(
      context:         context,
      relation_fields: [],
      meta:            meta,
      data:            data,
      id:              answer_id,
    )
  end

  let!(:knowledge_base) { create(:knowledge_base) }
  let!(:category)       { create(:knowledge_base_category, knowledge_base: knowledge_base) }
  let(:kb_locale)       { knowledge_base.kb_locales.first }
  let(:editor_role)     { create(:role, permission_names: 'knowledge_base.editor') }
  let(:user)            { create(:user, roles: [editor_role]) }
  let(:context)         { { current_user: user } }
  let(:additional_data) { {} }
  let(:meta)            { { initial: true, form_id: SecureRandom.uuid, additional_data: } }
  let(:data)            { {} }

  let(:answer) do
    create(:knowledge_base_answer, category:, translation_attributes: { title: 'Stored title', kb_locale: kb_locale })
  end
  let(:answer_id) { Gql::ZammadSchema.id_from_object(answer) }

  # Memoized: one round trip is one resolve, and a second one over the same updater would drop the
  #   initial values it already wrote into `data`.
  def fields
    @fields ||= begin
      updater.authorized?
      updater.resolve[:fields]
    end
  end

  def initial_value_of(field)
    fields.dig(field, :initialValue)
  end

  describe '#authorized?' do
    it 'authorizes an editor to edit the answer' do
      expect(updater.authorized?).to be true
    end

    context 'without an answer' do
      let(:answer_id) { nil }

      it 'is not authorized' do
        expect(updater.authorized?).to be false
      end
    end

    context 'with a reader' do
      let(:user) { create(:user, roles: [create(:role, permission_names: 'knowledge_base.reader')]) }

      it 'is not authorized' do
        expect(updater.authorized?).to be false
      end
    end

    # The global permission says nothing about the subtree the answer lives in.
    context 'with a granular editor of another subtree' do
      let(:other_category) { create(:knowledge_base_category, knowledge_base: knowledge_base) }

      before do
        create(:knowledge_base_permission, permissionable: knowledge_base, role: editor_role, access: 'reader')
        create(:knowledge_base_permission, permissionable: other_category, role: editor_role, access: 'editor')
      end

      # Refused where it is loaded, the way FormUpdater::Updater::KnowledgeBase::Category::Edit
      #   refuses a granular reader of its category.
      it 'is not authorized' do
        expect { updater.authorized? }.to raise_error(Exceptions::Forbidden)
      end
    end
  end

  describe 'initial values' do
    it 'seeds the answer as it is', :aggregate_failures do
      expect(initial_value_of('title')).to eq('Stored title')
      expect(initial_value_of('body')).to eq(answer.translations.sole.content.body)
      expect(initial_value_of('categoryId')).to eq(category.id)
      expect(initial_value_of('visibility')).to eq('draft')
    end

    # An editor cannot display `src="cid:…"`, so an answer with inline images would open without
    #   them. Handed over with URLs instead, exactly like a ticket shared draft's body.
    context 'when the body holds an inline image' do
      let(:content) { answer.translations.sole.content }

      before do
        content.update!(body: '<div>Text <img src="cid:inline-image" alt="Inline"></div>')

        create(:store,
               object:      content.class.name,
               o_id:        content.id,
               filename:    'inline.png',
               data:        'x',
               preferences: { 'Content-ID' => 'inline-image', 'Content-Type' => 'image/png' })
      end

      it 'seeds the body with the image URL rather than its cid' do
        expect(initial_value_of('body')).to include('/api/v1/attachments/')
      end

      # The `cid` attribute travels along, because that is what turns the URL back into `cid:` on
      #   save (HtmlSanitizer::CidToSrc) - without it the stored body would keep an absolute URL.
      it 'keeps the cid of the image' do
        expect(initial_value_of('body')).to include('cid="inline-image"')
      end
    end

    # Not `tags`: the form has no field for them at all, so there is nothing to seed. They are
    #   managed from the answer's sidebar, straight onto the record.
    it 'seeds no tags' do
      answer.tag_add('first', user.id)

      expect(fields).not_to have_key('tags')
    end

    # The tab edits one translation, and which one is the tab's business, not the answer's.
    context 'with a locale of its own' do
      let(:alternative_locale) do
        create(:knowledge_base_locale, knowledge_base: knowledge_base, system_locale: Locale.find_by(locale: 'lt'))
      end
      let(:additional_data) { { 'locale' => alternative_locale.system_locale.locale } }

      before do
        create(:knowledge_base_answer_translation, answer:, kb_locale: alternative_locale, title: 'Alternative title')
      end

      it 'seeds that translation' do
        expect(initial_value_of('title')).to eq('Alternative title')
      end

      # Adding one is a normal edit, so the form opens on empty fields rather than on the text of
      #   another locale.
      context 'when the answer has no translation in it' do
        let(:answer) do
          create(:knowledge_base_answer, category:, translation_attributes: { title: 'Stored title', kb_locale: kb_locale })
        end

        before { answer.translations.where.not(kb_locale: kb_locale).destroy_all }

        it 'seeds empty title and body', :aggregate_failures do
          expect(initial_value_of('title')).to eq('')
          expect(initial_value_of('body')).to eq('')
        end
      end
    end

    describe 'the publication state' do
      shared_examples 'seeding the state' do |state:, visibility:|
        context "with an #{state} answer" do
          let(:answer) do
            create(:knowledge_base_answer, state, category:, translation_attributes: { kb_locale: kb_locale })
          end

          it "seeds #{visibility}" do
            expect(initial_value_of('visibility')).to eq(visibility)
          end
        end
      end

      include_examples 'seeding the state', state: :draft,     visibility: 'draft'
      include_examples 'seeding the state', state: :internal,  visibility: 'internal'
      include_examples 'seeding the state', state: :published, visibility: 'published'
      include_examples 'seeding the state', state: :archived,  visibility: 'archived'

      # The form deals with the state the answer is in *now*, not with the one it is heading for: a
      #   transition scheduled for later belongs to the sidebar widget that manages it, and saving
      #   this form leaves it alone (Service::KnowledgeBase::Answer::Base#scheduled_publication?).
      context 'with a publication scheduled for later' do
        let(:answer) do
          create(:knowledge_base_answer, category:, published_at: 1.week.from_now,
                                         translation_attributes: { kb_locale: kb_locale })
        end

        it 'seeds the state the answer is still in', :aggregate_failures do
          expect(answer.visibility).to eq(:draft)
          expect(initial_value_of('visibility')).to eq('draft')
        end
      end

      # Publishing an internal answer keeps the date it went internal, and the state that counts is
      #   the last one that was set.
      context 'with an answer that went internal before it was published' do
        let(:answer) do
          create(:knowledge_base_answer, category:, internal_at: 2.weeks.ago, published_at: 1.week.ago,
                                         translation_attributes: { kb_locale: kb_locale })
        end

        it 'seeds the published state' do
          expect(initial_value_of('visibility')).to eq('published')
        end
      end
    end

    context 'when the form is not being initialized' do
      let(:meta) { { form_id: SecureRandom.uuid, additional_data: } }

      it 'seeds nothing' do
        expect(fields).not_to have_key('title')
      end
    end
  end

  # Saving replays the form's upload cache onto the answer, deleting every non-inline attachment it
  #   has first - so the answer's own files have to be in that cache before the form can be saved,
  #   and the field has to show their cached copies, because removing one goes through the cache too.
  describe 'attachments' do
    let(:form_id)         { SecureRandom.uuid }
    let(:taskbar)         { create(:taskbar, :with_knowledge_base_answer, answer:, user_id: user.id, state: taskbar_state) }
    let(:taskbar_state)   { nil }
    let(:additional_data) { { 'taskbarId' => Gql::ZammadSchema.id_from_object(taskbar) } }
    let(:meta)            { { initial: true, form_id: form_id, additional_data: } }

    before do
      taskbar
      UserInfo.with_user_id(user.id) do
        answer.add_attachment(File.open(Rails.root.join('spec/fixtures/files/image/squares.png')))
      end
    end

    it 'copies the answer files into the upload cache' do
      fields

      expect(UploadCache.new(form_id).attachments.map(&:filename)).to include('squares.png')
    end

    # As an *initial* value, not a plain one: these are the answer's own files, so they are what the
    #   form opens with rather than a change to it. A plain `value` leaves the field without a
    #   baseline, and it then reads as dirty from the moment the tab opens.
    it 'hands the field the cached copies as its baseline', :aggregate_failures do
      expect(fields.dig('attachments', :initialValue)).to include(include(name: 'squares.png'))
      expect(fields['attachments']).not_to have_key(:value)
    end

    # The cache is what the field reflects from the first round trip on, so seeding it again would
    #   bring back a file the editor removed from the draft but has not saved yet.
    context 'when the tab has already stored something' do
      let(:taskbar_state) { { 'form_id' => form_id } }

      it 'does not seed it again' do
        fields

        expect(UploadCache.new(form_id).attachments).to be_empty
      end
    end

    context 'without a taskbar' do
      let(:additional_data) { {} }

      it 'seeds nothing' do
        fields

        expect(UploadCache.new(form_id).attachments).to be_empty
      end
    end
  end

  describe 'the category field' do
    def category_options
      fields.dig('categoryId', :options)
    end

    it 'offers the categories the user may file an answer in, required', :aggregate_failures do
      expect(category_options).to include(include(value: category.id))
      expect(fields['categoryId']).to include(required: true)
    end

    # Editing an answer and filing one in its category are the same question
    #   (KnowledgeBase::AnswerPolicy#update? and KnowledgeBase::CategoryPolicy#create_answer? both
    #   ask for editor access to the category), so the answer's own category cannot be missing here.
    context 'with a granular editor of the answer subtree only' do
      let(:other_category) { create(:knowledge_base_category, knowledge_base: knowledge_base) }

      before do
        other_category
        create(:knowledge_base_permission, permissionable: knowledge_base, role: editor_role, access: 'reader')
        create(:knowledge_base_permission, permissionable: category, role: editor_role, access: 'editor')
      end

      it 'offers their own category and nothing else' do
        expect(category_options).to contain_exactly(include(value: category.id))
      end
    end
  end

  describe 'taskbar state' do
    let(:form_id)         { SecureRandom.uuid }
    let(:taskbar)         { create(:taskbar, :with_knowledge_base_answer, answer:, user_id: user.id, state: taskbar_state) }
    let(:taskbar_state)   { nil }
    let(:additional_data) { { 'taskbarId' => Gql::ZammadSchema.id_from_object(taskbar) } }
    let(:meta)            { { form_id: form_id, additional_data: } }

    # What the form sends back after it was opened: the answer's own values, untouched.
    let(:seeded_data) do
      {
        'title'      => 'Stored title',
        'body'       => answer.translations.sole.content.body,
        'categoryId' => category.id,
        'visibility' => 'draft',
      }
    end

    # The whole point of mapping the fields onto the answer: none of them is one of its columns, so
    #   an unmapped comparison would store every seeded value and report the tab as changed - which
    #   is what drives its dirty marker and the "editing" badge of the live user list.
    it 'stores nothing for a round trip that only echoes the answer', :aggregate_failures do
      data.merge!(seeded_data)

      fields

      expect(taskbar.reload.state).to eq('form_id' => form_id)
      expect(taskbar.reload).not_to be_state_changed
    end

    it 'stores what was typed', :aggregate_failures do
      data.merge!(seeded_data.merge('title' => 'Typed title'))

      fields

      expect(taskbar.reload.state).to include('title' => 'Typed title')
      expect(taskbar.reload).to be_state_changed
    end

    # A publication scheduled for later must not make an untouched tab look changed either: the form
    #   carries the state the answer is in *now*, which for a schedule that has not been reached is
    #   still `draft`.
    context 'with a scheduled answer' do
      let(:answer) do
        create(:knowledge_base_answer, category:, published_at: 1.week.from_now,
                                       translation_attributes: { title: 'Stored title', kb_locale: kb_locale })
      end

      it 'stores nothing for a round trip that only echoes it', :aggregate_failures do
        data.merge!(seeded_data)

        fields

        expect(taskbar.reload.state).to eq('form_id' => form_id)
        expect(taskbar.reload).not_to be_state_changed
      end
    end

    # Attachments need no mapping of their own, unlike the fields above: FormUpdater::StoreValue::Ignore
    #   keeps them out of every taskbar state there is, because the upload cache already persists them
    #   on its own. So the files the tab was seeded with cannot make it look changed - and neither can
    #   adding or removing one, which is a deliberate trade-off of that design, not of this updater.
    context 'with the attachments it was seeded with' do
      let(:answer) do
        create(:knowledge_base_answer, category:, translation_attributes: { title: 'Stored title', kb_locale: kb_locale })
      end

      before do
        UserInfo.with_user_id(user.id) do
          answer.add_attachment(File.open(Rails.root.join('spec/fixtures/files/image/squares.png')))
        end
      end

      it 'keeps them out of the stored state', :aggregate_failures do
        data.merge!(
          seeded_data.merge('attachments' => [{ 'name' => 'squares.png', 'size' => 22_198, 'type' => 'image/png' }])
        )

        fields

        expect(taskbar.reload.state).to eq('form_id' => form_id)
        expect(taskbar.reload).not_to be_state_changed
      end
    end

    # The other half of the mapping: a field the client reports as dirty that the draft does not
    #   carry is restored from the answer (AppliesTaskbarState#apply_taskbar_object_defaults) - the
    #   other half of the mapping above, which is what tells the updater what that value is.
    context 'when a dirty field is missing from the draft' do
      let(:additional_data) do
        { 'taskbarId' => Gql::ZammadSchema.id_from_object(taskbar), 'applyTaskbarState' => true }
      end
      let(:meta)          { { form_id: form_id, dirty_fields: ['categoryId'], additional_data: } }
      let(:taskbar_state) { { 'title' => 'Draft title', 'form_id' => form_id } }
      let(:data)          { { 'categoryId' => other_category_id } }

      let(:other_category_id) do
        create(:knowledge_base_category, knowledge_base: knowledge_base).id
      end

      it 'restores the answer own value for it' do
        expect(fields.dig('categoryId', :value)).to eq(category.id)
      end
    end

    # A form over an existing object resolves that object's own values on the first round trip, and
    #   storing them would turn every opened tab into a draft of nothing (no `store_state_on_initial`
    #   here, unlike the create updater).
    context 'when the form is being initialized' do
      let(:meta) { { initial: true, form_id: form_id, additional_data: } }

      it 'stores nothing' do
        data.merge!(seeded_data.merge('title' => 'Typed title'))

        expect { fields }.not_to change { taskbar.reload.state }
      end
    end

    context 'when applying the draft' do
      let(:additional_data) { { 'taskbarId' => Gql::ZammadSchema.id_from_object(taskbar), 'applyTaskbarState' => true } }
      let(:taskbar_state)   { { 'title' => 'Draft title', 'form_id' => form_id } }

      it 'plays the stored draft back over the answer' do
        expect(fields.dig('title', :value)).to eq('Draft title')
      end

      it 'stores nothing while doing so' do
        expect { fields }.not_to change { taskbar.reload.state }
      end
    end
  end
end
