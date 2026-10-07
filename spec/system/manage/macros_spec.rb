# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'system/examples/pagination_examples'

RSpec.describe 'Manage > Macro', type: :system do
  context 'when ajax pagination' do
    include_examples 'pagination', model: :macro, klass: Macro, path: 'manage/macros'
  end

  context 'when adding a checklist template action', current_user_id: 1 do
    let(:template) { create(:checklist_template, name: 'Onboarding checklist') }

    before { template }

    it 'saves the macro with the chosen template' do
      visit '/#manage/macros'
      click_on 'New Macro'

      in_modal do
        fill_in 'Name', with: 'Checklist macro'

        within '.ticket_perform_action' do
          find('.js-attributeSelector select').select 'Add checklist template'
          select 'Onboarding checklist', from: 'perform::checklist.add_from_template::checklist_template_id'
        end

        click_on 'Submit'
      end

      expect(Macro.last.perform).to eq('checklist.add_from_template' => { 'checklist_template_id' => template.id.to_s })
    end

    context 'when no checklist template is active' do
      let(:template) { create(:checklist_template, name: 'Onboarding checklist', active: false) }

      it 'does not save the macro without a template' do
        visit '/#manage/macros'
        click_on 'New Macro'

        in_modal do
          fill_in 'Name', with: 'Checklist macro'

          within '.ticket_perform_action' do
            find('.js-attributeSelector select').select 'Add checklist template'

            expect(page).to have_text('No checklist template available')
            expect(page).to have_no_css('.js-setChecklist select')
          end

          click_on 'Submit'

          expect(page).to have_css('.alert--danger', text: "The required 'perform' value for checklist.add_from_template, checklist_template_id is missing!")
        end

        expect(Macro.where(name: 'Checklist macro')).not_to exist
      end
    end
  end

  context 'when editing a macro whose checklist template is inactive', current_user_id: 1 do
    let(:template) { create(:checklist_template, name: 'Onboarding checklist', active: false) }
    let(:macro)    { create(:macro, name: 'Checklist macro', perform: { 'checklist.add_from_template' => { 'checklist_template_id' => template.id.to_s } }) }

    before { macro }

    it 'keeps the stored template selected and marked as inactive while no other template is active' do
      visit '/#manage/macros'
      find('tr', text: 'Checklist macro').click

      in_modal(disappears: true) do
        within '.ticket_perform_action' do
          expect(page).to have_select('perform::checklist.add_from_template::checklist_template_id', selected: 'Onboarding checklist (inactive)', options: ['Onboarding checklist (inactive)'])
          expect(page).to have_no_text('No checklist template available')
        end

        click_on 'Submit'
      end

      expect(macro.reload.perform).to eq('checklist.add_from_template' => { 'checklist_template_id' => template.id.to_s })
    end

    it 'keeps the stored template selected and marked as inactive when another template is active' do
      create(:checklist_template, name: 'Offboarding checklist')

      visit '/#manage/macros'
      find('tr', text: 'Checklist macro').click

      in_modal(disappears: true) do
        expect(page).to have_select('perform::checklist.add_from_template::checklist_template_id', selected: 'Onboarding checklist (inactive)', options: ['Offboarding checklist', 'Onboarding checklist (inactive)'])

        click_on 'Submit'
      end

      expect(macro.reload.perform).to eq('checklist.add_from_template' => { 'checklist_template_id' => template.id.to_s })
    end
  end
end
