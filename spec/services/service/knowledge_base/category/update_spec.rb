# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::KnowledgeBase::Category::Update do
  subject(:execute) do
    described_class.with_current_user(user).execute(category: record, category_data:, kb_locale:)
  end

  include_context 'basic Knowledge Base'

  let(:editor_role) { create(:role, permission_names: 'knowledge_base.editor') }
  let(:user)        { create(:user, roles: [editor_role]) }

  let(:record)      { category }
  let(:title)       { 'Renamed category' }
  let(:permissions) { nil }
  let(:kb_locale)   { primary_locale }
  # `parent` has three states: absent (leave the parent alone), an explicit `nil` (move to the top
  #   level) and a category (move there) — so it must never be built with `.compact`.
  let(:parent_data)   { {} }
  let(:category_data) { { title:, permissions: }.compact.merge(parent_data) }

  it 'writes the title into the given locale' do
    execute

    expect(record.reload.translation_to(primary_locale).title).to eq(title)
  end

  context 'with an icon' do
    let(:category_data) { { category_icon: 'f1ad' } }

    it 'updates the icon' do
      expect(execute.category_icon).to eq('f1ad')
    end
  end

  context 'with a title for one locale only' do
    before { record.translations.create!(kb_locale: alternative_locale, title: 'Kita kalba') }

    it 'keeps the titles of the locales that were not submitted' do
      execute

      expect(record.reload.translation_to(alternative_locale).title).to eq('Kita kalba')
    end
  end

  context 'with another locale' do
    let(:kb_locale) { alternative_locale }

    it 'writes the title into that locale only', :aggregate_failures do
      execute

      expect(record.reload.translation_to(alternative_locale).title).to eq(title)
      expect(record.reload.translation_to(primary_locale).title).not_to eq(title)
    end
  end

  # The GraphQL layer hands over what the client sent rather than resolving the record itself.
  context 'with a system locale code instead of a locale record' do
    let(:kb_locale) { alternative_locale.system_locale.locale }

    it 'writes the title into that locale' do
      execute

      expect(record.reload.translation_to(alternative_locale).title).to eq(title)
    end

    context 'when the knowledge base does not have that locale' do
      let(:kb_locale) { 'zh-cn' }

      it 'is rejected' do
        expect { execute }
          .to raise_error(Exceptions::UnprocessableContent, 'The selected language does not belong to this knowledge base.')
      end
    end
  end

  context 'with a title another sibling already uses' do
    let(:title) { other_category.translation_primary.title }

    it 'is rejected by the sibling title uniqueness' do
      expect { execute }.to raise_error(ActiveRecord::RecordInvalid, %r{Translations title has to be unique})
    end
  end

  describe 'moving' do
    context 'without a submitted parent' do
      let(:record) { subcategory }

      it 'leaves the parent alone' do
        execute

        expect(record.reload.parent_id).to eq(category.id)
      end
    end

    context 'with another parent' do
      let(:record)      { other_category }
      let(:target)      { create(:knowledge_base_category, knowledge_base:) }
      let(:parent_data) { { parent: target } }

      it 'moves the category and appends it to its new siblings' do
        create_list(:knowledge_base_category, 2, knowledge_base:, parent: target)

        execute

        expect(record.reload).to have_attributes(parent_id: target.id, position: 2)
      end

      context 'when the new parent has a child of the same title' do
        before do
          create(:knowledge_base_category, knowledge_base:, parent: target,
                                           translations: [build(:'knowledge_base/category/translation', title:, kb_locale: primary_locale)])
        end

        # Only a single save can catch this: sibling uniqueness is scoped through the category's
        #   `parent_id`, so the new title has to be validated against the siblings at the new place.
        it 'is rejected by the sibling title uniqueness' do
          expect { execute }.to raise_error(ActiveRecord::RecordInvalid, %r{Translations title has to be unique})
        end

        it 'moves nothing', :aggregate_failures do
          expect { execute }.to raise_error(ActiveRecord::RecordInvalid)

          expect(record.reload.parent_id).to be_nil
        end
      end
    end

    context 'with an explicit nil parent' do
      let(:record)      { subcategory }
      let(:parent_data) { { parent: nil } }

      it 'moves the category to the top level' do
        execute

        expect(record.reload).to have_attributes(parent_id: nil, position: 1)
      end
    end

    context 'with a parent below the category itself' do
      let(:parent_data) { { parent: subcategory } }

      it 'is rejected for the parent', :aggregate_failures do
        expect { execute }.to raise_error(ActiveRecord::RecordInvalid) do |error|
          expect(error.record.errors.attribute_names).to include(:parent_id)
        end
      end
    end

    context 'when the move would exceed the allowed nesting depth' do
      let(:record)      { other_category }
      let(:target)      { create(:knowledge_base_category, knowledge_base:) }
      let(:parent_data) { { parent: target } }

      # Stubbed after the fixtures of the shared context have been created at their real depth.
      before do
        target
        allow(KnowledgeBase::Category).to receive(:max_depth).and_return(1)
      end

      it 'is rejected for the parent' do
        expect { execute }.to raise_error(ActiveRecord::RecordInvalid, %r{exceed the allowed nesting depth})
      end
    end
  end

  context 'with permissions' do
    let(:other_role)  { create(:role, permission_names: 'knowledge_base.reader') }
    let(:permissions) { [{ role: other_role, access: 'none' }, { role: editor_role, access: 'editor' }] }

    it 'applies them to the category' do
      execute

      expect(record.reload.permissions.map { |permission| [permission.role_id, permission.access] })
        .to include([other_role.id, 'none'], [editor_role.id, 'editor'])
    end
  end

  context 'with permissions that lock the current user out' do
    let(:permissions) { [{ role: editor_role, access: 'reader' }] }

    # Named after the matrix, so a form can show the message below the field instead of on the form.
    it 'is rejected for the permissions attribute', :aggregate_failures do
      expect { execute }
        .to raise_error(Exceptions::InvalidAttribute) { |error| expect(error.attribute).to eq('permissions') }
    end

    it 'rolls the whole update back, including the title', :aggregate_failures do
      expect { execute }.to raise_error(Exceptions::InvalidAttribute)

      expect(record.reload.translation_primary.title).not_to eq(title)
    end
  end

  # Only an active knowledge base is editable — the legacy admin dialog is what activates it.
  context 'when the knowledge base is inactive' do
    before { knowledge_base.update!(active: false) }

    it 'is rejected' do
      expect { execute }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  # Editor access to the category is what allows editing it; a *move* is additionally authorized at
  #   the target, and only when the parent actually changes.
  context 'with a granular editor of one subtree' do
    let(:granular_role) { create(:role, permission_names: 'knowledge_base.editor') }
    let(:user)          { create(:user, roles: [granular_role]) }
    let(:record)        { subcategory }

    # Editor on the subcategory, only reader on its parent — the case the edit form is built for: it
    #   sends the stored parent back on every save even when that parent is not a permitted target.
    before do
      create(:knowledge_base_permission, permissionable: knowledge_base, role: granular_role, access: 'reader')
      create(:knowledge_base_permission, permissionable: subcategory, role: granular_role, access: 'editor')
    end

    context 'when resubmitting the unchanged parent' do
      let(:parent_data) { { parent: category } }

      it 'updates the category' do
        expect(execute.translation_to(primary_locale).title).to eq(title)
      end
    end

    context 'when moving the category to the top level' do
      let(:parent_data) { { parent: nil } }

      it 'is not authorized' do
        expect { execute }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context 'when updating a category they only read' do
      let(:record) { other_category }

      it 'is not authorized' do
        expect { execute }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  context 'with a user who may only read the knowledge base' do
    let(:user) { create(:user, roles: [create(:role, permission_names: 'knowledge_base.reader')]) }

    it 'is not authorized' do
      expect { execute }.to raise_error(Pundit::NotAuthorizedError)
    end
  end

  context 'without a current user' do
    it 'is rejected' do
      expect { described_class.execute(category: record, category_data:, kb_locale:) }
        .to raise_error(%r{Current user is required})
    end
  end
end
