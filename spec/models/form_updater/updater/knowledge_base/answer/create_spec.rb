# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe(FormUpdater::Updater::KnowledgeBase::Answer::Create) do
  subject(:updater) do
    described_class.new(
      context:         context,
      relation_fields: [],
      meta:            meta,
      data:            data,
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

  def fields
    updater.authorized?
    updater.resolve[:fields]
  end

  def title_of(record)
    record.translation_preferred(kb_locale).title
  end

  describe '#authorized?' do
    it 'authorizes an editor to add an answer' do
      expect(updater.authorized?).to be true
    end

    # An answer always belongs to a category, so — unlike for a new category — there is no top
    #   level left to create in when the knowledge base holds no category yet.
    context 'with a knowledge base without categories' do
      let(:category) { nil }

      it 'is not authorized to add an answer' do
        expect(updater.authorized?).to be false
      end
    end

    context 'without an active knowledge base' do
      before { knowledge_base.update!(active: false) }

      it 'is not authorized to add an answer' do
        expect(updater.authorized?).to be false
      end
    end

    context 'with a reader' do
      let(:user) { create(:user, roles: [create(:role, permission_names: 'knowledge_base.reader')]) }

      it 'is not authorized to add an answer' do
        expect(updater.authorized?).to be false
      end
    end

    context 'with a granular editor locked out of everything' do
      # Editor by role permission, but denied on the knowledge base and holding no category
      #   permission — so there is nowhere to file an answer.
      before { create(:knowledge_base_permission, permissionable: knowledge_base, role: editor_role, access: 'none') }

      it 'is not authorized to add an answer' do
        expect(updater.authorized?).to be false
      end
    end
  end

  describe '#resolve' do
    it 'offers the categories the user is an editor of, required' do
      expect(fields['categoryId']).to include(options: [{ value: category.id, label: title_of(category) }], required: true)
    end

    # The draft is one answer translation, so its category titles have to read in the locale the
    #   answer is written in — which the client sends along — and not in the editor's own.
    context 'with a locale of its own' do
      let(:alternative_locale) do
        create(:knowledge_base_locale, knowledge_base: knowledge_base, system_locale: Locale.find_by(locale: 'lt'))
      end

      let(:additional_data) { { 'locale' => 'lt' } }

      before do
        category.translations.create!(kb_locale: alternative_locale, title: 'Kategorija')
      end

      it 'labels the categories in the submitted locale' do
        expect(fields['categoryId'][:options]).to eq([{ value: category.id, label: 'Kategorija' }])
      end

      context 'when the knowledge base does not have it' do
        let(:additional_data) { { 'locale' => 'zz' } }

        # Only the labels are at stake here, unlike in a mutation, which must refuse to write into
        #   a locale it was not asked for.
        it 'falls back to the preferred locale' do
          expect(fields['categoryId'][:options]).to eq([{ value: category.id, label: title_of(category) }])
        end
      end
    end

    context 'with a granular editor of one subtree' do
      let!(:child) { create(:knowledge_base_category, knowledge_base: knowledge_base, parent: category) }

      # Reader on the knowledge base plus editor on one subcategory — the constructible granular
      #   setup: PermissionsUpdate only lets a child override a 'reader' parent. The extra
      #   category is the one outside the permitted subtree.
      before do
        create(:knowledge_base_category, knowledge_base: knowledge_base)
        create(:knowledge_base_permission, permissionable: knowledge_base, role: editor_role, access: 'reader')
        create(:knowledge_base_permission, permissionable: child, role: editor_role, access: 'editor')
      end

      it 'authorizes the answer' do
        expect(updater.authorized?).to be true
      end

      # The permitted category's own parent is reader-only for this user, so it is promoted to a
      #   root of the offered tree instead of being unreachable.
      it 'only offers the permitted subtree' do
        expect(fields['categoryId']).to include(options: [{ value: child.id, label: title_of(child) }])
      end
    end

    # Nothing seeds a timing alongside it: an answer without a timestamp is published right away,
    #   which is what the empty value of that field says.
    it 'starts as a draft to be published now', :aggregate_failures do
      expect(fields['visibility']).to eq(initialValue: 'draft')
      expect(fields).not_to include('scheduledAt')
    end

    # Without a category to start from the field stays empty for the user to pick — an
    #   `initialValue` would also overwrite whatever the caller seeded the form with (Form.vue).
    it 'does not preselect a category' do
      expect(fields['categoryId']).not_to have_key(:initialValue)
    end

    context 'when the tab was opened from a category' do
      let(:additional_data) { { 'categoryId' => category.id.to_s } }

      it 'preselects that category' do
        expect(fields['categoryId']).to include(initialValue: category.id)
      end

      # `taskbarId` travels in the same bag as a GraphQL id, so both forms have to be understood.
      context 'when it was passed as a GraphQL id' do
        let(:additional_data) { { 'categoryId' => Gql::ZammadSchema.id_from_object(category) } }

        it 'preselects that category' do
          expect(fields['categoryId']).to include(initialValue: category.id)
        end
      end

      context 'when the form already carries a category' do
        let(:other_category) { create(:knowledge_base_category, knowledge_base: knowledge_base) }
        let(:data)           { { 'categoryId' => other_category.id } }

        it 'keeps what the form has' do
          expect(fields['categoryId']).not_to have_key(:initialValue)
        end
      end

      context 'when the seeded category is not offered' do
        let(:forbidden_category) { create(:knowledge_base_category, knowledge_base: knowledge_base) }
        let(:additional_data)    { { 'categoryId' => forbidden_category.id.to_s } }

        before do
          create(:knowledge_base_permission, permissionable: knowledge_base, role: editor_role, access: 'reader')
          create(:knowledge_base_permission, permissionable: category, role: editor_role, access: 'editor')
        end

        # Preselecting it would put a value into the field that its own options cannot render.
        it 'ignores the seeded category' do
          expect(fields['categoryId']).not_to have_key(:initialValue)
        end
      end
    end

    context 'when the form is not being initialized' do
      let(:meta) { { initial: false, form_id: SecureRandom.uuid, additional_data: } }

      it 'refreshes the category options only', :aggregate_failures do
        expect(fields['categoryId']).to eq(options: [{ value: category.id, label: title_of(category) }], required: true)
        expect(fields).not_to include('visibility')
      end
    end
  end

  describe 'taskbar state' do
    let(:form_id)         { SecureRandom.uuid }
    let(:taskbar)         { create(:taskbar, :with_new_knowledge_base_answer, user_id: user.id, state: taskbar_state) }
    let(:taskbar_state)   { nil }
    let(:additional_data) { { 'taskbarId' => Gql::ZammadSchema.id_from_object(taskbar) } }
    let(:meta)            { { form_id: form_id, additional_data: } }

    context 'when storing the draft' do
      let(:data) do
        {
          'title'       => 'Draft answer',
          'categoryId'  => category.id,
          'tags'        => %w[tag1 tag2],
          'attachments' => [{ 'id' => 999, 'name' => 'lipsum.pdf', 'size' => '113746', 'type' => 'application/pdf' }],
        }
      end

      it 'stores every submitted field' do
        fields

        expect(taskbar.reload.state).to include(
          'title'      => 'Draft answer',
          'categoryId' => category.id,
          'tags'       => 'tag1, tag2',
        )
      end

      # The upload cache under the form id is where the draft files live (Taskbar::HasAttachments),
      #   so the state only has to carry the id they can be looked up with.
      it 'stores the form id instead of the attachments', :aggregate_failures do
        fields

        expect(taskbar.reload.state).to include('form_id' => form_id)
        expect(taskbar.reload.state).not_to have_key('attachments')
      end

      # A create screen has no object to fall back on, so its first round trip is stored as well
      #   (`store_state_on_initial`): the category the draft was opened for arrives with it, and
      #   nothing follows it - the taskbar link the tab is reopened through carries no query.
      context 'when the form is being initialized' do
        let(:meta) { { initial: true, form_id: form_id, additional_data: } }

        it 'stores every submitted field' do
          fields

          expect(taskbar.reload.state).to include(
            'title'      => 'Draft answer',
            'categoryId' => category.id,
            'tags'       => 'tag1, tag2',
          )
        end

        # Only a fresh tab is written: a draft that has been worked on already holds everything,
        #   and a reload - which still has the seed in its URL - must not push it back to the
        #   category it started in.
        context 'when the draft has been worked on' do
          let(:taskbar_state)  { { 'categoryId' => other_category.id, 'form_id' => form_id } }
          let(:other_category) { create(:knowledge_base_category, knowledge_base: knowledge_base) }
          let(:additional_data) do
            {
              'taskbarId'  => Gql::ZammadSchema.id_from_object(taskbar),
              'categoryId' => category.id,
            }
          end
          let(:data) { {} }

          it 'stores nothing' do
            expect { fields }.not_to change { taskbar.reload.state }
          end
        end
      end
    end

    context 'when applying the draft' do
      let(:additional_data) { { 'taskbarId' => Gql::ZammadSchema.id_from_object(taskbar), 'applyTaskbarState' => true } }
      let(:taskbar_state) do
        {
          'title'      => 'Draft answer',
          'categoryId' => category.id,
          'tags'       => 'tag1, tag2',
          'form_id'    => form_id,
        }
      end

      before do
        create(:store,
               object:      'UploadCache',
               o_id:        form_id,
               data:        'dGVzdCAxMjM=',
               filename:    'some_file.pdf',
               preferences: {
                 'Content-Type': 'application/pdf',
               })
      end

      it 'plays the stored draft back', :aggregate_failures do
        resolved_fields = fields

        expect(resolved_fields['title']).to include(value: 'Draft answer')
        expect(resolved_fields['categoryId'])
          .to include(value: category.id, options: [{ value: category.id, label: title_of(category) }])
        expect(resolved_fields['tags']).to include(value: %w[tag1 tag2])
      end

      # Unlike the seed of a fresh draft, the state is played back unfiltered - so a category the
      #   editor may no longer write to would come back selected in a field that does not even
      #   offer it, and fail on submit. The field is required, so an empty one makes them pick.
      context 'when the stored category is no longer offered' do
        # Editor on the category, reader on the knowledge base above it - the constructible
        #   granular shape, as in the context further up. The draft points at the other one.
        let(:other_category) { create(:knowledge_base_category, knowledge_base: knowledge_base) }

        let(:taskbar_state) do
          { 'title' => 'Draft answer', 'categoryId' => other_category.id, 'form_id' => form_id }
        end

        before do
          create(:knowledge_base_permission, permissionable: knowledge_base, role: editor_role, access: 'reader')
          create(:knowledge_base_permission, permissionable: category, role: editor_role, access: 'editor')
        end

        it 'plays it back without the category', :aggregate_failures do
          resolved_field = fields['categoryId']

          expect(resolved_field).not_to include(:value)
          expect(resolved_field[:options]).to eq([{ value: category.id, label: title_of(category) }])
        end
      end

      # The state deliberately holds no attachments; FormUpdater::ApplyValue::FormId restores them
      #   from the upload cache the stored form id points at.
      it 'restores the attachments from the upload cache' do
        expect(fields['attachments']).to include(
          value: [
            {
              id:   Gql::ZammadSchema.id_from_object(Store.last),
              name: 'some_file.pdf',
              size: '12',
              type: 'application/pdf',
            }
          ]
        )
      end

      it 'stores nothing' do
        expect { fields }.not_to change { taskbar.reload.state }
      end
    end
  end
end
