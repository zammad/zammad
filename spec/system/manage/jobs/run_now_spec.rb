# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Scheduler run now', type: :system do
  let(:job) do
    create(:job,
           name:      'Close old tickets',
           active:    false,
           object:    'Ticket',
           condition: { 'ticket.state_id' => { 'operator' => 'is', 'value' => [1] } },
           perform:   { 'ticket.state_id' => { 'value' => 4 } })
  end

  let(:running_state) { {} }

  before do
    job
    job.update_columns(running_state) if running_state.present?
    visit '#manage/job'
  end

  def open_row_action_menu
    within 'tr', text: job.name do
      find('.js-action').click
    end
  end

  it 'runs an inactive scheduler on demand after confirmation', performs_jobs: true do
    open_row_action_menu
    find('.js-table-action-menu .js-run-now').click

    in_modal do
      click_on 'Yes'
    end

    expect { perform_enqueued_jobs }.to change { job.reload.last_run_at }.from(nil)
  end

  it 'shows the finished run in the list without a reload', performs_jobs: true do
    open_row_action_menu
    find('.js-table-action-menu .js-run-now').click

    in_modal do
      click_on 'Yes'
    end

    perform_enqueued_jobs

    within 'tr', text: job.name do
      expect(page).to have_css('time', text: 'just now')
    end
  end

  context 'when the running flag is stuck for over a day' do
    let(:running_state) { { running: true, last_run_at: 2.days.ago } }

    it 'still offers the action' do
      open_row_action_menu

      expect(page).to have_css('.js-table-action-menu .js-run-now')
    end
  end

  context 'when the scheduler is running' do
    let(:running_state) { { running: true, last_run_at: 1.minute.ago } }

    it 'does not offer the action' do
      open_row_action_menu

      expect(page).to have_no_css('.js-table-action-menu .js-run-now')
    end
  end
end
