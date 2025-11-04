# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Scheduler next_run_at display', type: :system do
  let(:admin_user) { create(:admin) }
  let(:past_time)  { 10.minutes.ago }
  let(:job) do
    create(:job,
           name:        'Test Past Scheduler',
           active:      true,
           processed:   1,
           last_run_at: 1.day.ago,
           timeplan:    { 'days' => { 'Mon' => true }, 'hours' => { '0' => true } },
           timezone:    'UTC',
           object:      'Ticket',
           condition:   { 'ticket.state_id' => { 'operator' => 'is', 'value' => [1] } },
           perform:     { 'ticket.state_id' => { 'value' => 2 } }).tap do |j|
      # Otherwise model validation prevents setting next_run_at in the past
      j.update_columns(next_run_at: past_time)
    end
  end

  before do
    job
    visit '#manage/job'
  end

  it 'displays "due" for past next_run_at and includes absolute timestamp in title' do
    within 'tr', text: job.name do
      expect(page).to have_css('time', text: 'due') do |time_element|
        title_includes_date = time_element['title'].include?(past_time.strftime('%m/%d/%Y'))
        title_includes_timezone = job.timezone.present? ? time_element['title'].include?('UTC') : true
        title_includes_date && title_includes_timezone
      end
    end
  end
end
