# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# Ported from test/browser/agent_ticket_macro_test.rb. The remaining ux_flow_next_up
#   value 'next_from_overview' is already covered by 'next in overview macro changes URL'
#   in spec/system/ticket/zoom_spec.rb.
RSpec.describe 'Ticket zoom > Macro execution', authenticated_as: :authenticate, type: :system do
  let(:group)    { Group.find_by(name: 'Users') }
  let(:customer) { create(:customer) }
  let(:ticket)   { create(:ticket, group:, customer:) }

  def authenticate
    macro

    true
  end

  def perform_macro
    visit "#ticket/zoom/#{ticket.id}"

    within(:active_content) do
      click '.js-openDropdownMacro'
      click ".js-dropdownActionMacro[data-id=\"#{macro.id}\"]"
    end

    await_empty_ajax_queue
  end

  context "when using the seeded macro 'Close & Tag as Spam'" do
    let(:macro) { Macro.find_by(name: 'Close & Tag as Spam') }

    it 'closes the ticket, adds the spam tag and returns to the dashboard' do
      perform_macro

      expect(page).to have_current_path(%r{#dashboard}, url: true)
      expect(ticket.reload.state.name).to eq('closed')

      visit "#ticket/zoom/#{ticket.id}"

      expect(page).to have_css('.content.active .js-tag', text: 'spam')
      expect(page).to have_no_css('.content.active .js-tag', text: 'tag1')
    end
  end

  context "when the macro is configured with 'Stay on tab'" do
    let(:macro) do
      create(:macro,
             ux_flow_next_up: 'none',
             perform:         { 'ticket.tags' => { 'operator' => 'add', 'value' => 'spam' } })
    end

    it 'stays on the ticket tab and adds the tag' do
      perform_macro

      expect(page).to have_css('.content.active .js-tag', text: 'spam')
      expect(page).to have_no_css('.content.active .js-tag', text: 'tag1')
      expect(page).to have_current_path(%r{#ticket/zoom/#{ticket.id}}, url: true)
    end
  end

  context "when the macro is configured with 'Close tab'" do
    let(:macro) { create(:macro, ux_flow_next_up: 'next_task') }

    it 'closes the task tab' do
      perform_macro

      expect(page).to have_no_css(".tasks-navigation a[href=\"#ticket/zoom/#{ticket.id}\"]")
    end
  end
end
