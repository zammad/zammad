# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Channel::Filter::Database, type: :channel_filter do
  let(:mail_hash) { Channel::EmailParser.new.parse(<<~RAW.chomp) }
    From: daffy.duck@acme.corp
    To: batman@marvell.com
    Subject: Anvil

    I can haz anvil!
  RAW

  context 'with a single filter' do
    let(:filter_1) { create(:postmaster_filter, perform: { 'x-zammad-ticket-title' => { 'value' => 'test' } }) }

    before { filter_1 }

    it 'processes the email' do
      filter(mail_hash)

      expect(mail_hash[:'x-zammad-ticket-title']).to eq('test')
    end

    it 'logs the filter processing', aggregate_failures: true do
      allow(Rails.logger).to receive(:debug)
      allow_any_instance_of(FilterProcessor).to receive(:process)
      filter(mail_hash)

      expect(Rails.logger).to have_received(:debug).with(no_args) do |&block|
        expect(block.call).to match(" process filter #{filter_1.name} ...")
      end
    end
  end

  context 'with multiple filters' do
    let(:filter_1) { create(:postmaster_filter, name: 'K', perform: { 'x-zammad-ticket-title' => { 'value' => 'KKK' } }) }
    let(:filter_2) { create(:postmaster_filter, name: 'Z', perform: { 'x-zammad-ticket-title' => { 'value' => 'ZZZ' } }) }
    let(:filter_3) { create(:postmaster_filter, name: 'A', perform: { 'x-zammad-ticket-title' => { 'value' => 'AAA' } }) }

    before { filter_1 && filter_2 && filter_3 }

    it 'applies the final filter' do
      filter(mail_hash)

      expect(mail_hash[:'x-zammad-ticket-title']).to eq('ZZZ')
    end

    it 'logs the filters in correct order' do
      calls = []
      allow(Rails.logger).to receive(:debug) { |&block| calls << block.call }
      allow_any_instance_of(FilterProcessor).to receive(:process)

      filter(mail_hash)

      expect(calls).to eq([
                            " process filter #{filter_3.name} ...",
                            " process filter #{filter_1.name} ...",
                            " process filter #{filter_2.name} ..."
                          ])
    end
  end
end
