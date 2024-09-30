# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Manage > Checklists', current_user_id: 1, type: :system do
  context 'when enabling/disabling checklists' do
    before do
      visit 'manage/checklists'
    end

    it 'can enable/disable checklists' do
      expect(Setting.get('checklist')).to be(true)

      find('.js-checklistSetting').click

      wait.until { Setting.get('checklist') == false }
    end
  end

  context 'when adding a new checklist' do
    before do
      visit 'manage/checklists'
    end

    it 'shows a help text' do
      expect(page).to have_content('With checklist templates it is possible to pre-fill new checklists with initial items.')
      expect(page).to have_no_css('.js-description')
    end

    context 'when items are empty' do
      it 'shows an error message' do
        expect(page).to have_link('New Checklist Template')

        click_on('New Checklist Template')

        in_modal do
          fill_in('Name', with: 'Test Checklist')
          click_on('Submit')
          expect(page).to have_content('Please add at least one item to the checklist.')
        end
      end
    end

    context 'when items are present' do
      it 'adds a new checklist' do
        expect(page).to have_link('New Checklist Template')

        click_on('New Checklist Template')

        in_modal do
          fill_in('Name', with: 'Test Checklist')
          find('.checklist-item-add-item-text').fill_in(with: 'Test Item')
          click_on('Add')
          click_on('Submit')
        end

        expect(page).to have_content('Test Checklist')
      end
    end
  end

  context 'when editing a checklist' do
    before do
      create(:checklist_template, name: 'Test Checklist')

      visit 'manage/checklists'
    end

    it 'shows a description button' do
      expect(page).to have_no_content('With checklist templates it is possible to pre-fill new checklists with initial items.')
      expect(page).to have_css('.js-description')

      page.find('.js-description').click

      in_modal do
        expect(page).to have_content('With checklist templates it is possible to pre-fill new checklists with initial items.')
      end
    end

    it 'successfully updates the checklist' do
      expect(page).to have_content('Test Checklist')

      find('.js-checklistTemplatesTable tr.item').click

      in_modal do
        find('.checklist-item-add-item-text').fill_in(with: 'Test Item')
        click_on('Add')
        click_on('Submit')
      end

      expect(ChecklistTemplate.last.items.count).to eq(6)
      expect(ChecklistTemplate.last.items.last.text).to eq('Test Item')
    end
  end

  context 'when cloning a checklist' do
    before do
      create(:checklist_template, name: 'Test Checklist')

      visit 'manage/checklists'
    end

    it 'successfully creates a clone' do
      expect(page).to have_content('Test Checklist')

      find('.js-checklistTemplatesTable tr.item .js-action').click
      find('.js-table-action-menu .js-clone').click

      in_modal do
        click_on('Submit')
      end

      expect(page).to have_content('Clone: Test Checklist')

      expect(ChecklistTemplate.last.items.count).to eq(5)
    end
  end

  context 'when deleting a checklist' do
    before do
      create(:checklist_template, name: 'Test Checklist')

      visit 'manage/checklists'
    end

    it 'successfully creates a clone' do
      expect(page).to have_content('Test Checklist')

      find('.js-checklistTemplatesTable tr.item .js-action').click
      find('.js-table-action-menu .js-delete').click

      in_modal do
        click_on('delete')
      end

      expect(page).to have_no_content('Test Checklist')

      expect(ChecklistTemplate.count).to eq(0)
    end
  end
end
