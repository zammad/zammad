# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Channel::Filter::Database, type: :channel_filter do
  let(:mail_hash) { Channel::EmailParser.new.parse(<<~RAW.chomp) }
    From: daffy.duck@acme.corp
    To: batman@marvell.com
    Subject: Anvil

    I can haz anvil!
  RAW

  describe '.filter_matches?' do
    let(:filter) { create(:postmaster_filter, match: { 'from' => { 'operator' => operator, 'value' => value } }) }

    shared_examples 'the filter matches' do
      it 'matches' do
        expect(described_class.filter_matches?(mail_hash, filter)).to be true
      end
    end

    shared_examples 'the filter does not match' do
      it 'matches' do
        expect(described_class.filter_matches?(mail_hash, filter)).to be false
      end
    end

    context "with operator 'contains'" do
      let(:operator) { 'contains' }

      context 'with matching string' do
        let(:value) { 'a' }

        include_examples 'the filter matches'
      end

      context 'with matching upcased string' do
        let(:value) { 'A' }

        include_examples 'the filter matches'
      end

      context 'with non-matching string' do
        let(:value) { 'x' }

        include_examples 'the filter does not match'
      end
    end

    context "with operator 'contains not'" do
      let(:operator) { 'contains not' }

      context 'with matching string' do
        let(:value) { 'a' }

        include_examples 'the filter does not match'
      end

      context 'with matching upcased string' do
        let(:value) { 'A' }

        include_examples 'the filter does not match'
      end

      context 'with non-matching string' do
        let(:value) { 'x' }

        include_examples 'the filter matches'
      end
    end

    context "with operator 'is'" do
      let(:operator) { 'is' }

      context 'with matching string' do
        let(:value) { 'daffy.duck@acme.corp' }

        include_examples 'the filter matches'
      end

      context 'with matching upcased string' do
        let(:value) { 'Daffy.Duck@acme.corp' }

        include_examples 'the filter does not match'
      end

      context 'with non-matching string' do
        let(:value) { 'other.address@example.com' }

        include_examples 'the filter does not match'
      end
    end

    context "with operator 'is not'" do
      let(:operator) { 'is not' }

      context 'with matching string' do
        let(:value) { 'daffy.duck@acme.corp' }

        include_examples 'the filter does not match'
      end

      context 'with matching upcased string' do
        let(:value) { 'Daffy.Duck@acme.corp' }

        include_examples 'the filter matches'
      end

      context 'with non-matching string' do
        let(:value) { 'other.address@example.com' }

        include_examples 'the filter matches'
      end
    end

    context "with operator 'starts with'" do
      let(:operator) { 'starts with' }

      context 'with matching string' do
        let(:value) { 'daffy.duck' }

        include_examples 'the filter matches'
      end

      context 'with matching upcased string' do
        let(:value) { 'Daffy.Duck' }

        include_examples 'the filter matches'
      end

      context 'with non-matching string' do
        let(:value) { 'other.address' }

        include_examples 'the filter does not match'
      end
    end

    context "with operator 'ends with'" do
      let(:operator) { 'ends with' }

      context 'with matching string' do
        let(:value) { 'acme.corp' }

        include_examples 'the filter matches'
      end

      context 'with matching upcased string' do
        let(:value) { 'ACME.corp' }

        include_examples 'the filter matches'
      end

      context 'with non-matching string' do
        let(:value) { 'example.com' }

        include_examples 'the filter does not match'
      end
    end
  end

  describe 'Cannot set date for pending close status in postmaster filter #4206', db_strategy: :reset do
    before do
      freeze_time

      create(:object_manager_attribute_date, name: '4206_date')
      create(:object_manager_attribute_datetime, name: '4206_datetime')
      create(:postmaster_filter, perform: {
               'x-zammad-ticket-pending_time'  => { 'operator' => 'relative', 'value' => '12', 'range' => 'minute' },
               'x-zammad-ticket-state_id'      => { 'value' => Ticket::State.find_by(name: 'pending reminder').id },
               'x-zammad-ticket-4206_datetime' => { 'operator' => 'static', 'value' => '2022-08-18T06:00:00.000Z' },
               'x-zammad-ticket-4206_date'     => { 'value' => '2022-08-19' }
             })
      ObjectManager::Attribute.migration_execute
      filter(mail_hash)
    end

    it 'does set values for pending time' do
      expect(mail_hash['x-zammad-ticket-pending_time']).to eq(12.minutes.from_now)
    end

    it 'does set values for state_id' do
      expect(mail_hash['x-zammad-ticket-state_id']).to eq(Ticket::State.find_by(name: 'pending reminder').id)
    end

    it 'does set values for 4206_datetime' do
      expect(mail_hash['x-zammad-ticket-4206_datetime']).to eq('2022-08-18T06:00:00.000Z')
    end

    it 'does set values for 4206_date' do
      expect(mail_hash['x-zammad-ticket-4206_date']).to eq('2022-08-19')
    end
  end
end
