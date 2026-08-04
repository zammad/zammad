# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# Ported from test/browser/agent_ticket_create_default_type_test.rb and
#   agent_ticket_create_available_types_test.rb (#1987): the channel type tabs of
#   the ticket create mask follow the ui_ticket_create_available_types and
#   ui_ticket_create_default_type settings.
RSpec.describe 'Scenario > Ticket create channel types', authenticated_as: :authenticate, type: :system do
  let(:agent) { create(:agent, groups: [Group.find_by(name: 'Users')]) }

  def authenticate
    setting

    agent
  end

  before do
    visit 'ticket/create'
  end

  context 'with the default configuration' do
    let(:setting) { true }

    it 'offers all types with phone-in active' do
      within(:active_content) do
        expect(page).to have_css('.type-tabs li.active[data-type=phone-in]')
        expect(page).to have_css('.type-tabs li[data-type=phone-out]')
        expect(page).to have_css('.type-tabs li[data-type=email-out]')
      end
    end
  end

  context 'with a reduced set of available types' do
    let(:setting) { Setting.set('ui_ticket_create_available_types', %w[email-out phone-out]) }

    it 'hides the disabled type' do
      within(:active_content) do
        expect(page).to have_no_css('.type-tabs li[data-type=phone-in]')
        expect(page).to have_css('.type-tabs li[data-type=phone-out]')
        expect(page).to have_css('.type-tabs li[data-type=email-out]')
      end
    end
  end

  context 'with a single available type' do
    let(:setting) { Setting.set('ui_ticket_create_available_types', %w[email-out]) }

    it 'renders no type tabs at all' do
      within(:active_content) do
        expect(page).to have_css('.newTicket')
        expect(page).to have_no_css('.type-tabs')
      end
    end
  end

  context 'with a configured default type' do
    let(:setting) { Setting.set('ui_ticket_create_default_type', 'email-out') }

    it 'activates the configured type tab' do
      within(:active_content) do
        expect(page).to have_css('.type-tabs li.active[data-type=email-out]')
      end
    end
  end
end
