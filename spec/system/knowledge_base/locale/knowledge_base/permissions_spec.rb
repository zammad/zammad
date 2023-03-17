# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Knowledge Base Locale Knowledge Base Permissions', type: :system do
  include_context 'basic Knowledge Base'

  let(:role_editor)         { Role.find_by name: 'Admin' }
  let(:role_another_editor) { create(:role, permission_names: %w[knowledge_base.editor]) }
  let(:role_reader)         { Role.find_by name: 'Agent' }

  it 'shows roles with has KB permissions only' do
    open_page

    in_modal do
      expect(page)
        .to have_text(%r{Admin}i)
        .and(have_text(%r{Agent}i))
        .and(have_no_text(%r{Customer}i))
    end
  end

  describe 'permissions shown' do
    it 'shows existing permissions when KB has no permissions' do
      open_page

      in_modal do
        expect(page)
          .to have_css("input[name='#{role_editor.id}'][value='editor'][checked]:not([disabled])", visible: :all)
          .and(have_css("input[name='#{role_editor.id}'][value='reader']:not([disabled])", visible: :all))
          .and(have_css("input[name='#{role_editor.id}'][value='none']:not([disabled])", visible: :all))
      end
    end

    it 'shows existing permissions' do
      KnowledgeBase::PermissionsUpdate.new(knowledge_base).update! role_another_editor => 'reader'

      open_page

      in_modal do
        expect(page)
          .to have_css("input[name='#{role_another_editor.id}'][value='reader'][checked]:not([disabled])", visible: :all)
          .and(have_css("input[name='#{role_another_editor.id}'][value='editor']:not([disabled])", visible: :all))
          .and(have_css("input[name='#{role_another_editor.id}'][value='none']:not([disabled])", visible: :all))
      end
    end

    it 'shows reader permissions limited by role itself' do
      open_page

      in_modal do
        expect(page)
          .to have_css("input[name='#{role_reader.id}'][value='none']:not([disabled])", visible: :all)
          .and(have_css("input[name='#{role_reader.id}'][value='reader'][checked]:not([disabled])", visible: :all))
          .and(have_css("input[name='#{role_reader.id}'][value='editor'][disabled]", visible: :all))
      end
    end
  end

  describe 'saving changes' do
    it 'saves permissions' do
      role_another_editor

      open_page

      in_modal do
        find("input[name='#{role_another_editor.id}'][value='reader']", visible: :all)
          .ancestor('label')
          .click

        click_on 'Submit'
      end

      expect(knowledge_base.reload.permissions)
        .to contain_exactly(
          have_attributes(role: role_reader, access: 'reader', permissionable: knowledge_base),
          have_attributes(role: role_another_editor, access: 'reader', permissionable: knowledge_base),
          have_attributes(role: role_editor, access: 'editor', permissionable: knowledge_base)
        )
    end

    it 'allows to modify existing permissions' do
      KnowledgeBase::PermissionsUpdate.new(knowledge_base).update! role_another_editor => 'reader'

      open_page

      in_modal do
        find("input[name='#{role_another_editor.id}'][value='editor']", visible: :all)
          .ancestor('label')
          .click

        click_on 'Submit'
      end

      expect(knowledge_base.reload.permissions)
        .to contain_exactly(
          have_attributes(role: role_reader, access: 'reader', permissionable: knowledge_base),
          have_attributes(role: role_another_editor, access: 'editor', permissionable: knowledge_base),
          have_attributes(role: role_editor, access: 'editor', permissionable: knowledge_base)
        )
    end

    it 'does not allow to lock user himself' do
      open_page

      in_modal do
        find("input[name='#{role_editor.id}'][value='reader']", visible: :all)
          .ancestor('label')
          .click

        click_on 'Submit'

        expect(page).to have_css('.alert')
      end
    end
  end

  def open_page
    visit "knowledge_base/#{knowledge_base.id}/locale/#{Locale.first.locale}/edit"

    find('[data-action=permissions]').click
  end
end
