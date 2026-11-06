# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::Tool::Locator::Ticket, :aggregate_failures do
  let(:ticket) { create(:ticket) }
  let(:other)  { create(:ticket) }

  before do
    Setting.set('fqdn', 'support.example.com')
    Setting.set('ticket_hook', 'Ticket#')
    Setting.set('ticket_hook_divider', '')
  end

  def located(**arguments)
    described_class.new(arguments.stringify_keys).record_id
  end

  describe '.link' do
    def reference(url)
      described_class.link(url)&.to_h
    end

    it 'reads the current interface\'s links, also with a message, a tab or behind another view' do
      [
        'https://support.example.com/#ticket/zoom/8812',
        'https://support.example.com/#ticket/zoom/8812/5015',
        'https://support.example.com/#ticket/zoom/8812/nav/1',
        'https://support.example.com/desktop/#ticket/zoom/8812',
        'http://SUPPORT.example.com/#ticket/zoom/8812',
        '#ticket/zoom/8812',
      ].each do |url|
        expect(reference(url)).to eq({ id: 8812, number: nil }), url
      end

      expect(reference('https://support.example.com/#ticket/zoom/number/31042')).to eq(id: nil, number: '31042')
    end

    it 'reads the desktop view\'s and the mobile view\'s links' do
      [
        'https://support.example.com/desktop/tickets/8812',
        'https://support.example.com/desktop/tickets/8812/5015',
        'https://support.example.com/desktop/ticket/zoom/8812',
        'https://support.example.com/mobile/tickets/8812',
        'https://support.example.com/mobile/ticket/8812',
        '/desktop/tickets/8812',
      ].each do |url|
        expect(reference(url)).to eq({ id: 8812, number: nil }), url
      end
    end

    it 'takes the alternative address, and the port where the address names one' do
      Setting.set('alternative_fqdn', 'help.example.com')
      expect(reference('https://help.example.com/#ticket/zoom/8812')).to eq(id: 8812, number: nil)

      Setting.set('fqdn', 'localhost:3000')
      expect(reference('http://localhost:3000/#ticket/zoom/8812')).to eq(id: 8812, number: nil)
      expect(reference('http://localhost:4000/#ticket/zoom/8812')).to be_nil
    end

    it 'names no ticket for a link to another system, to something else or no link at all' do
      [
        'https://other.example.com/#ticket/zoom/8812',
        'other.example.com/#ticket/zoom/8812',
        'other.example.com/desktop/tickets/8812',
        'https://support.example.com/#user/profile/2',
        'https://support.example.com/desktop/users/2',
        'https://support.example.com/#ticket/zoom/',
        'javascript:alert(1)//#ticket/zoom/8812',
        'mailto:support@example.com',
        'not a link',
        '',
      ].each do |url|
        expect(reference(url)).to be_nil, url
      end
    end
  end

  describe '#record_id' do
    it 'finds a ticket by its ID, by a link and by its number as people write it' do
      expect(located(ticket_id: ticket.id)).to eq(ticket.id)
      expect(located(ticket_url: "https://support.example.com/#ticket/zoom/#{ticket.id}")).to eq(ticket.id)
      expect(located(ticket_url: "https://support.example.com/#ticket/zoom/number/#{ticket.number}")).to eq(ticket.id)

      [ticket.number, "##{ticket.number}", "Ticket##{ticket.number}", "Ticket# #{ticket.number}", "[Ticket##{ticket.number}]", " #{ticket.number} "].each do |number|
        expect(located(ticket_number: number)).to eq(ticket.id), number
      end
    end

    it 'reads the ticket hook as configured' do
      Setting.set('ticket_hook', 'Case')
      Setting.set('ticket_hook_divider', '-')

      expect(located(ticket_number: "Case-#{ticket.number}")).to eq(ticket.id)
    end

    it 'takes the most exact name that can be used: the ID, then the link, then the number' do
      link = "https://support.example.com/#ticket/zoom/#{other.id}"

      expect(located(ticket_id: ticket.id, ticket_url: link, ticket_number: other.number)).to eq(ticket.id)
      expect(located(ticket_url: link, ticket_number: ticket.number)).to eq(other.id)
      expect(located(ticket_url: 'https://other.example.com/#ticket/zoom/1', ticket_number: ticket.number)).to eq(ticket.id)
    end

    it 'finds nothing for a number no ticket has, and for no name' do
      expect(located(ticket_number: '000')).to be_nil
      expect(located).to be_nil
    end
  end

  describe '.argument_errors' do
    it 'refuses a link that names no ticket only where nothing else names one' do
      expect(described_class.argument_errors({ 'ticket_url' => 'https://other.example.com/#ticket/zoom/1' })).to eq([described_class::NO_LINK])
      expect(described_class.argument_errors({ 'ticket_url' => 'https://other.example.com/', 'ticket_number' => '31042' })).to be_empty
      expect(described_class.argument_errors({ 'ticket_url' => 'https://other.example.com/', 'ticket_id' => 1 })).to be_empty
      expect(described_class.argument_errors({ 'ticket_url' => 'https://support.example.com/#ticket/zoom/1' })).to be_empty
    end
  end

  describe '#named_by?' do
    let(:group)  { create(:group) }
    let(:agent)  { create(:agent, groups: [group]) }
    let(:ticket) { create(:ticket, group:) }
    let(:other)  { create(:ticket, group:) }

    def named?(texts: [], ids: [], **arguments)
      described_class.new(arguments.stringify_keys).named_by?(ids:, texts:, user: agent)
    end

    it 'accepts a ticket among the given ones, whichever way the caller names it' do
      expect(named?(ids: [ticket.id], ticket_id: ticket.id)).to be(true)
      expect(named?(ids: [ticket.id], ticket_number: "Ticket##{ticket.number}")).to be(true)
      expect(named?(ids: [ticket.id], ticket_url: "https://support.example.com/desktop/tickets/#{ticket.id}")).to be(true)
      expect(named?(ids: [ticket.id], ticket_id: other.id)).to be(false)
    end

    it 'accepts a ticket the agent named by its number, its ID or a link, whichever way the caller names it' do
      expect(named?(texts: ["Did we solve this as in #{ticket.number}?"], ticket_id: ticket.id)).to be(true)
      expect(named?(texts: ["Compare with Ticket##{ticket.number}."], ticket_number: ticket.number)).to be(true)
      expect(named?(texts: ["Look at https://support.example.com/#ticket/zoom/#{ticket.id} please"], ticket_number: ticket.number)).to be(true)
      expect(named?(texts: ["Read the ticket with ID #{ticket.id}."], ticket_id: ticket.id)).to be(true)
    end

    it 'decides on what was named, also for a number no ticket has, so that the answer tells nothing of other tickets' do
      expect(named?(texts: ['What about 99999123?'], ticket_number: '99999123')).to be(true)
      expect(named?(ticket_number: '99999123')).to be(false)
      expect(named?(texts: ['Nothing here.'], ticket_number: ticket.number)).to be(false)
    end

    it 'does not take a number the agent wrote for an ID, as dates and amounts are numbers too' do
      expect(named?(texts: ["Refund #{ticket.id} EUR."], ticket_id: ticket.id)).to be(false)
    end

    it 'names a ticket across the forms only where the user may read it, so that nothing tells another one apart' do
      hidden = create(:ticket)
      texts  = ["Compare with ID #{hidden.id} and https://support.example.com/#ticket/zoom/#{hidden.id}."]

      expect(named?(texts:, ticket_number: hidden.number)).to be(false)
      expect(named?(texts:, ticket_number: '99999123')).to be(false)
      expect(named?(texts: ["Compare with #{hidden.number}."], ticket_id: hidden.id)).to be(false)
      expect(named?(texts:, ticket_id: hidden.id)).to be(true)
    end

    it 'reads a link at the end of a sentence' do
      expect(named?(texts: ["Compare with https://support.example.com/#ticket/zoom/#{ticket.id}."], ticket_id: ticket.id)).to be(true)
      expect(named?(texts: ["(see https://support.example.com/desktop/tickets/#{ticket.id})"], ticket_number: ticket.number)).to be(true)
    end
  end
end
