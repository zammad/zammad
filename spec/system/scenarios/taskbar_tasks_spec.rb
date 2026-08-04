# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# Ported from test/browser/taskbar_task_test.rb as a continuous end-to-end scenario:
#   a new-ticket task persists its form state across reload and a real re-login, is
#   invisible for other users and restores for its owner. Closing new-ticket tasks
#   is covered by 'when closing taskbar tab for new ticket creation' in create_spec.
RSpec.describe 'Scenario > Taskbar tasks', authenticated_as: :authenticate, authentication_type: :form, type: :system do
  let(:group)       { Group.find_by(name: 'Users') }
  let(:agent)       { create(:agent, password: 'test', groups: [group]) }
  let(:other_agent) { create(:agent, password: 'test', groups: [group]) }

  def authenticate
    other_agent

    agent
  end

  it 'persists new ticket tasks per user across reload and re-login' do
    visit '#ticket/create'

    within(:active_content) do
      find('[name="title"]').fill_in with: 'some test AAA'
    end

    # Wait until the task state got persisted to the taskbar.
    wait.until { Taskbar.last&.state.to_s.include?('some test AAA') }

    # The form state survives a reload.
    page.refresh

    within(:active_content) do
      expect(find('[name="title"]').value).to eq('some test AAA')
    end

    # Another user does not see the task at all.
    logout
    login(username: other_agent.login, password: 'test')

    expect(page).to have_no_text('some test AAA')

    # The owner gets the task back after re-login, including the form state.
    logout
    login(username: agent.login, password: 'test')

    expect(page).to have_css('.tasks-navigation .task')

    find('.tasks-navigation .task', text: %r{.*}).click

    within(:active_content) do
      expect(find('[name="title"]').value).to eq('some test AAA')
    end
  end
end
