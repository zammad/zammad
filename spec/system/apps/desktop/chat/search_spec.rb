# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Desktop > Chat > Search', app: :desktop_view, authenticated_as: :agent, searchindex: true, type: :playwright do
  let(:topic)     { create(:chat, name: 'Support') }
  let(:agent)     { create(:agent) }
  let(:colleague) { create(:agent, firstname: 'Berta', lastname: 'Beispiel') }

  # Closed, so the index holds its messages: a session is indexed when it is saved, not per message.
  let(:closed_session) do
    create(:'chat/session', chat: topic, state: 'closed', user: colleague, name: 'Printer reconnect').tap do |session|
      create(:'chat/message', chat_session: session, content: 'How do I reconnect the shared printer?', created_by_id: nil)
      create(:'chat/message', chat_session: session, content: 'Remove it and add it again with your new password.', created_by: colleague)
    end
  end

  let(:running_session) do
    create(:'chat/session', chat: topic, state: 'running', user: colleague, name: 'VPN setup').tap do |session|
      create(:'chat/message', chat_session: session, content: 'My VPN is down.', created_by_id: nil)
    end
  end

  let(:quick_search) { main_sidebar.get_by_role('searchbox', name: 'Search…') }

  before do
    Setting.set('chat', true)
    closed_session
    running_session
    searchindex_model_reload([Chat::Session])

    open_desktop('/')
  end

  it 'finds a closed session by a word of its conversation and reads it' do
    quick_search.fill('printer')

    expect(main_sidebar).to contain_text('Found chat sessions')

    main_sidebar.get_by_role('link', name: "##{closed_session.id} Printer reconnect").click

    window = main_content.get_by_role('region', name: 'Printer reconnect')

    expect(window).to contain_text('Remove it and add it again with your new password.')
    expect(window).to contain_text('This conversation is closed.')
    expect(window.get_by_role('textbox', name: 'Message')).to have_count(0)
  end

  it 'reads the running session of a colleague without a way to write into it' do
    quick_search.fill('vpn')

    main_sidebar.get_by_role('link', name: "##{running_session.id} VPN setup").click

    window = main_content.get_by_role('region', name: 'VPN setup')

    expect(window).to contain_text('My VPN is down.')
    expect(window).to contain_text('This conversation is handled by Berta Beispiel.')
    expect(window.get_by_role('textbox', name: 'Message')).to have_count(0)
    expect(window.get_by_role('button', name: 'Disconnect')).to have_count(0)

    window.get_by_role('button', name: 'Close window').click

    expect(main_content.get_by_role('region', name: 'VPN setup')).to have_count(0)
  end

  # Reached by clicking rather than by visiting the URL, which does not establish the taskbar tab.
  it 'lists the sessions found in the detailed search, sorts them by number and opens one' do
    quick_search.fill('Support')

    expect(main_sidebar).to contain_text('Found chat sessions')
    main_sidebar.get_by_role('link', name: 'detailed search').click

    main_content.get_by_role('tab', name: 'Chat session').click

    table = main_content.get_by_role('table', name: 'Search result for: Chat session')

    ['Number', 'Name', 'State', 'Created at'].each do |column|
      expect(table.get_by_role('columnheader', name: column)).to be_visible
    end
    expect(table).to contain_text('Running')

    table.get_by_role('button', name: 'Sort by Number ascending').click
    expect(table.get_by_role('row').nth(1)).to contain_text('Printer reconnect')

    table.get_by_role('button', name: 'Sort by Number descending').click
    expect(table.get_by_role('row').nth(1)).to contain_text('VPN setup')

    table.get_by_role('link', name: closed_session.id.to_s, exact: true).click

    expect(main_content.get_by_role('region', name: 'Printer reconnect')).to contain_text('This conversation is closed.')
  end
end
