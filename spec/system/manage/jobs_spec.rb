# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'system/examples/pagination_examples'

RSpec.describe 'Manage > Job', type: :system do
  context 'when ajax pagination' do
    include_examples 'pagination', model: :job, klass: Job, path: 'manage/job'
  end

  context 'when adding a checklist template action', current_user_id: 1 do
    let(:template) { create(:checklist_template, name: 'Onboarding checklist') }

    before { template }

    it 'offers the checklist action for the ticket object only' do
      visit '/#manage/job'
      click_on 'New Scheduler'

      in_modal do
        scroll_into_view('.object_perform_action')

        within '.object_perform_action' do
          find('.js-attributeSelector select').select 'Add checklist template'

          expect(page).to have_select('perform::checklist.add_from_template::checklist_template_id', options: ['Onboarding checklist'])
        end

        select 'User', from: 'object'

        expect(page).to have_css('.object_perform_action .js-attributeSelector option[value="user.active"]')
        expect(page).to have_no_css('.object_perform_action .js-attributeSelector option[value="checklist.add_from_template"]')
      end
    end
  end

  context 'when adding a checklist condition' do
    it 'offers the checklist condition for the ticket object only' do
      visit '/#manage/job'
      click_on 'New Scheduler'

      in_modal do
        scroll_into_view('.object_selector')

        within '.object_selector' do
          find('.js-attributeSelector select').select 'Has checklist'

          expect(page).to have_no_select('condition::ticket.checklist_existing::operator')
          expect(page).to have_select('condition::ticket.checklist_existing::value', options: %w[yes no])
        end

        select 'User', from: 'object'

        expect(page).to have_css('.object_selector .js-attributeSelector option[value="user.role_ids"]')
        expect(page).to have_no_css('.object_selector .js-attributeSelector option[value="ticket.checklist_existing"]')
      end
    end
  end

  context 'when editing a stored checklist condition while the checklist feature is disabled' do
    let(:condition) { { 'ticket.checklist_existing' => { 'operator' => 'is', 'value' => true } } }
    let(:job)       { create(:job, name: 'Checklist job', condition: condition) }

    before do
      Setting.set('checklist', false)
      job
    end

    it 'keeps the stored condition when the job is edited' do
      visit '/#manage/job'
      find('tr', text: 'Checklist job').click

      in_modal(disappears: true) do
        scroll_into_view('.object_selector')

        within '.object_selector' do
          expect(page).to have_select('condition::ticket.checklist_existing::value', selected: 'yes')
        end

        fill_in 'Name', with: 'Renamed checklist job'
        click_on 'Submit'
      end

      expect(job.reload).to have_attributes(name: 'Renamed checklist job', condition: condition)
    end

    context 'with expert conditions' do
      let(:condition) do
        {
          'operator'   => 'OR',
          'conditions' => [
            { 'name' => 'ticket.checklist_existing', 'operator' => 'is', 'value' => 'true' },
          ],
        }
      end

      before { Setting.set('ticket_allow_expert_conditions', true) }

      it 'keeps the stored condition when the job is edited' do
        visit '/#manage/job'
        find('tr', text: 'Checklist job').click

        in_modal(disappears: true) do
          scroll_into_view('.object_selector')

          within '.object_selector' do
            expect(find('.js-attributeSelector select').value).to eq('ticket.checklist_existing')
            expect(find('.js-expertConditions input', visible: :all).value).to include('ticket.checklist_existing')
          end

          fill_in 'Name', with: 'Renamed checklist job'
          click_on 'Submit'
        end

        expect(job.reload).to have_attributes(name: 'Renamed checklist job', condition: condition)
      end
    end
  end

  context 'when editing a stored checklist template action', current_user_id: 1 do
    let(:template) { create(:checklist_template, name: 'Onboarding checklist') }
    let(:perform)  { { 'checklist.add_from_template' => { 'checklist_template_id' => template.id.to_s } } }

    # Offered for tickets and users alike, so switching the object keeps it.
    let(:condition) { { 'organization.name' => { 'operator' => 'contains', 'value' => 'Zammad' } } }

    before { create(:job, name: 'Checklist job', condition: condition, perform: perform) }

    it 'drops the action when the job is switched to the user object' do
      visit '/#manage/job'
      find('tr', text: 'Checklist job').click

      in_modal(disappears: true) do
        scroll_into_view('.object_perform_action')

        within '.object_perform_action' do
          expect(page).to have_select('perform::checklist.add_from_template::checklist_template_id', selected: 'Onboarding checklist')
        end

        select 'User', from: 'object'

        within '.object_perform_action' do
          expect(page).to have_no_select('perform::checklist.add_from_template::checklist_template_id')
          expect(page).to have_select('perform::user.active::value', selected: 'active')
        end

        click_on 'Submit'
      end

      expect(Job.find_by(name: 'Checklist job')).to have_attributes(object: 'User', condition: condition, perform: { 'user.active' => { 'value' => true } })
    end
  end
end
