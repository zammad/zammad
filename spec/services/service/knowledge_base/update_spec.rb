# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::KnowledgeBase::Update do
  subject(:execute) do
    described_class.with_current_user(user).execute(knowledge_base_data:, kb_locale:)
  end

  include_context 'basic Knowledge Base'

  let(:editor_role) { create(:role, permission_names: 'knowledge_base.editor') }
  let(:user)        { create(:user, roles: [editor_role]) }

  let(:title)               { 'Renamed knowledge base' }
  let(:footer_note)         { '© Renamed' }
  let(:permissions)         { nil }
  let(:kb_locale)           { primary_locale }
  let(:knowledge_base_data) { { title:, footer_note:, permissions: }.compact }

  # The service resolves the single knowledge base itself, so it has to exist before the call —
  #   the shared context creates it lazily.
  before { knowledge_base }

  it 'returns the updated knowledge base' do
    expect(execute).to eq(knowledge_base)
  end

  it 'writes the texts into the given locale' do
    execute

    expect(knowledge_base.reload.translation_to(primary_locale)).to have_attributes(title:, footer_note:)
  end

  context 'with texts for one locale only' do
    before do
      knowledge_base.translations.create!(kb_locale: alternative_locale, title: 'Kita žinių bazė', footer_note: '© Kita')
    end

    it 'keeps the texts of the locales that were not submitted' do
      execute

      expect(knowledge_base.reload.translation_to(alternative_locale).title).to eq('Kita žinių bazė')
    end
  end

  # A locale added after the knowledge base was created has no translation yet.
  context 'with a locale that has no translation yet' do
    let(:kb_locale) { alternative_locale }

    it 'creates the translation' do
      execute

      expect(knowledge_base.reload.translation_to(alternative_locale)).to have_attributes(title:, footer_note:)
    end

    it 'leaves the other locales alone' do
      execute

      expect(knowledge_base.reload.translation_to(primary_locale).title).not_to eq(title)
    end
  end

  # The GraphQL layer hands over what the client sent rather than resolving the record itself.
  context 'with a system locale code instead of a locale record' do
    let(:kb_locale) { alternative_locale.system_locale.locale }

    before { alternative_locale }

    it 'writes the texts into that locale' do
      execute

      expect(knowledge_base.reload.translation_to(alternative_locale)).to have_attributes(title:, footer_note:)
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

    it 'applies them to the knowledge base' do
      execute

      expect(knowledge_base.reload.permissions.map { |permission| [permission.role_id, permission.access] })
        .to include([other_role.id, 'none'], [editor_role.id, 'editor'])
    end
  end

  # The form offers the matrix before any permission exists, so saving it untouched must not be
  #   what switches the whole instance to granular permissions.
  context 'with permissions that only restate what the roles have anyway' do
    let(:other_role)  { create(:role, permission_names: 'knowledge_base.reader') }
    let(:permissions) { [{ role: other_role, access: 'reader' }, { role: editor_role, access: 'editor' }] }

    it 'stores none of them', :aggregate_failures do
      execute

      expect(knowledge_base.reload.permissions).to be_empty
      expect(KnowledgeBase).not_to be_granular_permissions
    end

    it 'still saves the rest of the form' do
      execute

      expect(knowledge_base.reload.translation_to(primary_locale).title).to eq(title)
    end

    context 'when granular permissions are already in use' do
      before { create(:knowledge_base_permission, permissionable: knowledge_base, role: editor_role, access: 'editor') }

      it 'applies them like any other selection' do
        execute

        expect(knowledge_base.reload.permissions.map { |permission| [permission.role_id, permission.access] })
          .to include([other_role.id, 'reader'], [editor_role.id, 'editor'])
      end
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

      expect(knowledge_base.reload.translation_to(primary_locale).title).not_to eq(title)
    end
  end

  # Only an active knowledge base is editable — the legacy admin dialog is what activates it.
  context 'when the knowledge base is inactive' do
    before { knowledge_base.update!(active: false) }

    it 'is rejected' do
      expect { execute }.to raise_error(ActiveRecord::RecordNotFound)
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
      expect { described_class.execute(knowledge_base_data:, kb_locale:) }
        .to raise_error(%r{Current user is required})
    end
  end
end
