# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Knowledge Base Locale Category Permissions', type: :system do
  include_context 'basic Knowledge Base'

  let(:role_editor)         { Role.find_by name: 'Admin' }
  let(:role_another_editor) { create(:role, permission_names: %w[knowledge_base.editor]) }
  let(:role_reader)         { Role.find_by name: 'Agent' }

  let(:child_category) { create(:knowledge_base_category, parent: category) }

  it 'shows roles with has KB permissions only' do
    open_page category

    in_modal do
      expect(page)
        .to have_text(%r{Admin}i)
        .and(have_text(%r{Agent}i))
        .and(have_no_text(%r{Customer}i))
    end
  end

  describe 'permissions shown' do
    it 'shows existing permissions when category has no permissions' do
      open_page category

      in_modal do
        expect(page)
          .to have_css("input[name='#{role_editor.id}'][value='editor'][checked]:not([disabled])", visible: :all)
          .and(have_css("input[name='#{role_editor.id}'][value='reader']:not([disabled])", visible: :all))
          .and(have_css("input[name='#{role_editor.id}'][value='none']:not([disabled])", visible: :all))
      end
    end

    it 'shows existing permissions when category has inerited permissions only' do
      KnowledgeBase::PermissionsUpdate.new(category).update! role_reader => 'none'

      open_page category

      in_modal do
        expect(page)
          .to have_css("input[name='#{role_reader.id}'][value='reader']:not([disabled])", visible: :all)
          .and(have_css("input[name='#{role_reader.id}'][value='none'][checked]:not([disabled])", visible: :all))
          .and(have_css("input[name='#{role_reader.id}'][value='editor'][disabled]", visible: :all))
      end
    end

    it 'shows existing permissions' do
      KnowledgeBase::PermissionsUpdate.new(child_category).update! role_reader => 'none'

      open_page child_category

      in_modal do
        expect(page)
          .to have_css("input[name='#{role_reader.id}'][value='reader']:not([disabled])", visible: :all)
          .and(have_css("input[name='#{role_reader.id}'][value='none'][checked]:not([disabled])", visible: :all))
          .and(have_css("input[name='#{role_reader.id}'][value='editor'][disabled]", visible: :all))
      end
    end

    it 'shows editor permission not limited by parent category being read only' do
      KnowledgeBase::PermissionsUpdate.new(category).update! role_another_editor => 'reader'

      open_page child_category

      in_modal do
        expect(page)
          .to have_css("input[name='#{role_another_editor.id}'][value='none']:not([disabled])", visible: :all)
          .and(have_css("input[name='#{role_another_editor.id}'][value='reader'][checked]:not([disabled])", visible: :all))
          .and(have_css("input[name='#{role_another_editor.id}'][value='editor'][disabled]", visible: :all))
      end
    end

    it 'shows editor permissions limited by parent category' do
      KnowledgeBase::PermissionsUpdate.new(category).update! role_another_editor => 'none'

      open_page child_category

      in_modal do
        expect(page)
          .to have_css("input[name='#{role_another_editor.id}'][value='none'][checked]:not([disabled])", visible: :all)
          .and(have_css("input[name='#{role_another_editor.id}'][value='reader'][disabled]", visible: :all))
          .and(have_css("input[name='#{role_another_editor.id}'][value='editor'][disabled]", visible: :all))
      end
    end

    it 'shows reader permissions limited by parent category' do
      KnowledgeBase::PermissionsUpdate.new(category).update! role_reader => 'none'

      open_page child_category

      in_modal do
        expect(page)
          .to have_css("input[name='#{role_reader.id}'][value='none'][checked]:not([disabled])", visible: :all)
          .and(have_css("input[name='#{role_reader.id}'][value='reader'][disabled]", visible: :all))
          .and(have_css("input[name='#{role_reader.id}'][value='editor'][disabled]", visible: :all))
      end
    end

    it 'shows reader permissions limited by role itself' do
      open_page child_category

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
      open_page category

      in_modal do
        find("input[name='#{role_reader.id}'][value='none']", visible: :all)
          .ancestor('label')
          .click

        click_on 'Submit'
      end

      expect(category.reload.permissions)
        .to contain_exactly(
          have_attributes(role: role_reader, access: 'none', permissionable: category),
          have_attributes(role: role_editor, access: 'editor', permissionable: category)
        )
    end

    it 'allows to modify existing permissions' do
      KnowledgeBase::PermissionsUpdate.new(category).update! role_reader => 'none'

      open_page category

      in_modal do
        find("input[name='#{role_reader.id}'][value='reader']", visible: :all)
          .ancestor('label')
          .click

        click_on 'Submit'
      end

      expect(category.reload.permissions)
        .to contain_exactly(
          have_attributes(role: role_reader, access: 'reader', permissionable: category),
          have_attributes(role: role_editor, access: 'editor', permissionable: category)
        )
    end

    it 'does not allow to lock user himself' do
      open_page category

      in_modal do
        find("input[name='#{role_editor.id}'][value='reader']", visible: :all)
          .ancestor('label')
          .click

        click_on 'Submit'

        expect(page).to have_css('.alert')
      end
    end
  end

  def open_page(category)
    visit "knowledge_base/#{knowledge_base.id}/locale/#{Locale.first.locale}/category/#{category.id}/edit"

    find('[data-action=permissions]').click
  end
end
