# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket zoom > Sidebar i-doit', type: :system do
  let(:endpoint)     { 'https://idoit.example.com/i-doit/' }
  let(:object_id)    { '26' }
  let(:agent)        { create(:agent, groups: Group.all) }
  let(:ticket)       { create(:ticket, title: 'Ticket with i-doit object', group: Group.first, preferences: { idoit: { object_ids: [object_id] } }) }
  let(:other_ticket) { create(:ticket, title: 'Ticket without i-doit object', group: Group.first) }

  let(:idoit_response) do
    {
      'jsonrpc' => '2.0',
      'result'  => [
        {
          'id'                => object_id,
          'title'             => 'demo.example.com',
          'type_title'        => 'Virtual server',
          'cmdb_status_title' => 'in operation',
        },
      ],
    }
  end

  before do
    Setting.set('idoit_integration', true)
    Setting.set('idoit_config', { api_token: 'some_token', endpoint: endpoint, client_id: '' })

    # WebMock is disabled in system specs, so the i-doit JSON-RPC call is stubbed at the HTTP client.
    allow(UserAgent).to receive(:post).and_call_original
    allow(UserAgent).to receive(:post)
      .with("#{endpoint}src/jsonrpc.php", hash_including(method: 'cmdb.objects'), anything)
      .and_return(UserAgent::Result.new(success: true, code: 200, data: idoit_response))
  end

  def open_idoit_sidebar
    visit "#ticket/zoom/#{ticket.id}"
    click '.tabsSidebar-tab[data-tab=idoit]'
  end

  context 'with Elasticsearch', authenticated_as: :authenticate, searchindex: true do
    def authenticate
      ticket && other_ticket
      searchindex_model_reload([Ticket])
      agent
    end

    it 'searches for tickets linked to the object when clicking its ID' do
      open_idoit_sidebar

      within '.sidebar[data-tab=idoit]' do
        find('.js-idoitObjectId', text: "ID: #{object_id}").click
      end

      expect(page).to have_field(id: 'global-search', with: "preferences.idoit.object_ids:#{object_id}")

      within '.global-search-result' do
        expect(page).to have_text(ticket.title)
        expect(page).to have_no_text(other_ticket.title)
      end
    end
  end

  context 'without Elasticsearch', authenticated_as: :agent do
    it 'shows the object ID as plain text' do
      open_idoit_sidebar

      within '.sidebar[data-tab=idoit]' do
        expect(page).to have_text("ID: #{object_id}")
        expect(page).to have_no_css('.js-idoitObjectId')
      end
    end
  end
end
