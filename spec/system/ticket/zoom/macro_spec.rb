# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# Ported from test/browser/agent_ticket_macro_test.rb. The remaining ux_flow_next_up
#   value 'next_from_overview' is already covered by 'next in overview macro changes URL'
#   in spec/system/ticket/zoom/navigation_spec.rb.
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

  context 'when the macro adds a checklist template', current_user_id: 1 do
    let(:template) { create(:checklist_template, items: ['Template item 1', 'Template item 2']) }
    let(:macro) do
      create(:macro,
             ux_flow_next_up: 'none',
             perform:         { 'checklist.add_from_template' => { 'checklist_template_id' => template.id.to_s } })
    end

    def authenticate
      Setting.set('checklist', true)

      true
    end

    # Created here rather than in authenticate: the login hook runs before current_user_id is set,
    #   and the template items need a creator.
    before { macro }

    it 'adds the checklist and shows its items in the sidebar' do
      perform_macro

      expect(ticket.reload.checklist.sorted_items.map(&:text)).to eq(['Template item 1', 'Template item 2'])

      open_checklist_sidebar

      expect(page).to have_css('.sidebar[data-tab=checklist] .checklistShow', text: 'Template item 1')
      expect(page).to have_css('.sidebar[data-tab=checklist] .checklistShow', text: 'Template item 2')
    end
  end

  describe 'Macros', authenticated_as: :authenticate do
    let(:macro_body) { 'macro <b>body</b>' }
    let(:macro)      { create(:macro, perform: { 'article.note' => { 'body' => macro_body, 'internal' => 'true', 'subject' => 'macro note' } }) }
    let!(:ticket)    { create(:ticket, group: Group.find_by(name: 'Users')) }

    def authenticate
      macro
      true
    end

    it 'does html macro by default' do
      visit "ticket/zoom/#{ticket.id}"
      find('.js-openDropdownMacro').click
      find(:macro, macro.id).click

      wait.until { ticket.reload.articles.last&.body == macro_body }
      expect(ticket.articles.last.content_type).to eq('text/html')
    end
  end

  describe 'Error “customer_id required” on Macro execution #4022', authenticated_as: :authenticate do
    let(:ticket) { create(:ticket, group: Group.first) }
    let(:macro) { create(:macro, perform: { 'ticket.customer_id'=>{ 'pre_condition' => 'current_user.id', 'value' => nil, 'value_completion' => '' } }) }

    def authenticate
      ticket && macro

      true
    end

    before do
      visit "#ticket/zoom/#{ticket.id}"
    end

    it 'does set the agent as customer via macro' do
      click '.js-openDropdownMacro'
      page.find(:macro, macro.id).click
      wait.until { ticket.reload.customer_id == User.find_by(email: 'admin@example.com').id }
    end
  end

  describe 'Setting relative pending reminder times via macro results in an "Missing required value for field pending_time! error #5880', authenticated_as: :authenticate do
    let(:macro) { create(:macro, name: 'set custom pending', perform: { 'ticket.state_id' => { 'value' => '3' }, 'ticket.pending_time' => { 'operator' => 'relative', 'value' => '1', 'range' => 'week' } }) }

    def authenticate
      macro
      true
    end

    it 'does change the state via macro' do
      visit "#ticket/zoom/#{Ticket.first.id}"
      click '.js-openDropdownMacro'
      find(:macro, macro.id).click
      wait.until { Ticket.first.state.name == 'pending reminder' && Ticket.first.pending_time.present? }
    end
  end
end
