# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::KnowledgeBase::Category::Create do
  subject(:execute) do
    described_class.with_current_user(user).execute(category_data:, kb_locale:)
  end

  include_context 'basic Knowledge Base'

  let(:editor_role) { create(:role, permission_names: 'knowledge_base.editor') }
  let(:user)        { create(:user, roles: [editor_role]) }

  let(:title)         { 'Fresh category' }
  let(:category_icon) { 'f1ad' }
  let(:permissions)   { nil }
  let(:parent)        { nil }
  let(:kb_locale)     { primary_locale }
  let(:category_data) { { category_icon:, title:, parent:, permissions: }.compact }

  # The service resolves the single knowledge base itself, so it has to exist before the call —
  #   the shared context creates it lazily.
  before { knowledge_base }

  it 'creates a top level category', :aggregate_failures do
    expect(execute).to have_attributes(knowledge_base:, parent: nil, category_icon:)
    expect(execute.translation_to(primary_locale).title).to eq(title)
  end

  context 'with a parent category' do
    let(:parent) { category }

    it 'creates the category below it' do
      expect(execute.parent).to eq(category)
    end

    it 'appends it to its siblings' do
      create_list(:knowledge_base_category, 2, knowledge_base:, parent: category)

      expect(execute.position).to eq(2)
    end

    # This path submits no sorting mode, so the model's create-time inheritance is what fills the
    #   two columns (KnowledgeBase::Category#inherit_sorting_modes) and the GraphQL input needs no
    #   argument for them.
    it 'follows the sorting modes of the parent, per list' do
      parent.update!(category_sorting_mode: 'last_update', answer_sorting_mode: 'manual')

      expect(execute).to have_attributes(category_sorting_mode: 'last_update', answer_sorting_mode: 'manual')
    end
  end

  # The root lists categories only, so there is no answer mode above a top level category to
  #   inherit — see KnowledgeBase::Category#inherit_sorting_modes.
  it 'takes the knowledge base category mode and the default answer mode at the top level' do
    knowledge_base.update!(category_sorting_mode: 'last_update')

    expect(execute)
      .to have_attributes(category_sorting_mode: 'last_update', answer_sorting_mode: KnowledgeBase::DEFAULT_SORTING_MODE)
  end

  context 'without an icon' do
    let(:category_icon) { nil }

    it 'falls back to the default icon of the knowledge base' do
      expect(execute.category_icon).to eq(knowledge_base.default_category_icon)
    end
  end

  context 'without a title' do
    let(:title) { nil }

    # The model has no such validation: a category without a single translation saves fine and
    #   then shows up as a nameless row in every list.
    it 'is rejected' do
      expect { execute }.to raise_error(Exceptions::UnprocessableContent, 'A title is required.')
    end

    it 'creates no category', :aggregate_failures do
      expect { execute }.to raise_error(Exceptions::UnprocessableContent)

      expect(KnowledgeBase::Category.count).to be_zero
    end
  end

  context 'with a title another sibling already uses' do
    let(:title) { category.translation_primary.title }

    it 'is rejected by the sibling title uniqueness' do
      expect { execute }.to raise_error(ActiveRecord::RecordInvalid, %r{Translations title has to be unique})
    end
  end

  # The GraphQL layer hands over what the client sent rather than resolving the record itself.
  context 'with a system locale code instead of a locale record' do
    let(:kb_locale) { alternative_locale.system_locale.locale }

    before { alternative_locale }

    it 'writes the title into that locale', :aggregate_failures do
      expect(execute.translation_to(alternative_locale).title).to eq(title)
      expect(execute.translation_to(primary_locale)).to be_nil
    end

    context 'when the knowledge base does not have that locale' do
      let(:kb_locale) { 'zh-cn' }

      it 'is rejected' do
        expect { execute }
          .to raise_error(Exceptions::UnprocessableContent, 'The selected language does not belong to this knowledge base.')
      end
    end
  end

  context 'with permissions' do
    let(:other_role)  { create(:role, permission_names: 'knowledge_base.reader') }
    let(:permissions) { [{ role: other_role, access: 'none' }, { role: editor_role, access: 'editor' }] }

    it 'applies them to the new category' do
      expect(execute.permissions.map { |permission| [permission.role_id, permission.access] })
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

    it 'rolls the whole creation back', :aggregate_failures do
      expect { execute }.to raise_error(Exceptions::InvalidAttribute)

      expect(KnowledgeBase::Category.count).to be_zero
    end
  end

  # Only an active knowledge base is editable — the legacy admin dialog is what activates it.
  context 'when the knowledge base is inactive' do
    before { knowledge_base.update!(active: false) }

    it 'is rejected' do
      expect { execute }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  # Where a category may be created is decided by CategoryPolicy#create?, which asks the parent —
  #   or the knowledge base for a top level category.
  context 'with a granular editor of one subtree' do
    let(:granular_role) { create(:role, permission_names: 'knowledge_base.editor') }
    let(:user)          { create(:user, roles: [granular_role]) }

    # Reader on the knowledge base plus editor on one category — the only constructible granular
    #   setup, since KnowledgeBase::PermissionsUpdate lets a child override a 'reader' parent only.
    before do
      create(:knowledge_base_permission, permissionable: knowledge_base, role: granular_role, access: 'reader')
      create(:knowledge_base_permission, permissionable: category, role: granular_role, access: 'editor')
    end

    context 'when creating below the permitted category' do
      let(:parent) { category }

      it 'creates the category' do
        expect(execute.parent).to eq(category)
      end
    end

    context 'when creating at the top level' do
      it 'is not authorized' do
        expect { execute }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    # Refused by the same check that refuses the top level above, which asks the parent.
    context 'when creating below a category they only read' do
      let(:parent) { other_category }

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
      expect { described_class.execute(category_data:, kb_locale:) }
        .to raise_error(%r{Current user is required})
    end
  end
end
