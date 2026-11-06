# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::Tool::Runtime::Result, :aggregate_failures do
  it 'sends the content as JSON to the model unless the tool gives a text' do
    expect(described_class.ok({ title: 'Printer' })).to have_attributes(status: 'ok', content: { title: 'Printer' }, text: '{"title":"Printer"}', ok?: true)
    expect(described_class.ok({ title: 'Printer' }, text: 'Ticket "Printer"')).to have_attributes(text: 'Ticket "Printer"')
  end

  it 'carries an error code and a message' do
    expect(described_class.error('not_found', 'Not found.'))
      .to have_attributes(status: 'error', content: { error: 'not_found', message: 'Not found.' }, text: '{"error":"not_found","message":"Not found."}', ok?: false)
  end

  it 'keeps what an error carries for the events out of the text the model reads' do
    expect(described_class.error('not_loaded', 'It is loaded now.', content: { tools: [{ name: 'read_invoice' }] }))
      .to have_attributes(content: { error: 'not_loaded', message: 'It is loaded now.', tools: [{ name: 'read_invoice' }] }, text: '{"error":"not_loaded","message":"It is loaded now."}')
  end

  describe '.from' do
    it 'takes what a tool returned' do
      result = described_class.ok({ title: 'Printer' })

      expect(described_class.from(result)).to be(result)
      expect(described_class.from({ 'title' => 'Printer' })).to have_attributes(status: 'ok', content: { title: 'Printer' })
      expect(described_class.from({ 'error' => 'not_found', 'message' => 'Not found.' })).to have_attributes(status: 'error', content: { error: 'not_found', message: 'Not found.' })
    end
  end
end
