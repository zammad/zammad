# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

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

    context "with operator 'matches regex'" do
      let(:operator) { 'matches regex' }

      context 'with matching string' do
        let(:value) { 'daffy.duck@.*' }

        include_examples 'the filter matches'
      end

      context 'with non-matching string' do
        let(:value) { 'daffy.duck.+@' }

        include_examples 'the filter does not match'
      end
    end

    context "with operator 'does not match regex'" do
      let(:operator) { 'does not match regex' }

      context 'with matching string' do
        let(:value) { 'daffy.duck@.*' }

        include_examples 'the filter does not match'
      end

      context 'with non-matching string' do
        let(:value) { 'daffy.duck.+@' }

        include_examples 'the filter matches'
      end
    end

    context "with operator 'is any of'" do
      let(:operator) { 'is any of' }

      context 'with matching string' do
        let(:value) { ['daffy.duck@acme.corp', 'elmer.fudd@acme.corp'] }

        include_examples 'the filter matches'
      end

      context 'with matching upcased string' do
        let(:value) { ['Daffy.Duck@acme.corp', 'Elmer.Fudd@acme.corp'] }

        include_examples 'the filter does not match'
      end

      context 'with non-matching string' do
        let(:value) { ['other.address@example.com', 'mail@example.com'] }

        include_examples 'the filter does not match'
      end
    end

    context "with operator 'is none of'" do
      let(:operator) { 'is none of' }

      context 'with matching string' do
        let(:value) { ['daffy.duck@acme.corp', 'elmer.fudd@acme.corp'] }

        include_examples 'the filter does not match'
      end

      context 'with matching upcased string' do
        let(:value) { ['Daffy.Duck@acme.corp', 'Elmer.Fudd@acme.corp'] }

        include_examples 'the filter matches'
      end

      context 'with non-matching string' do
        let(:value) { ['other.address@example.com', 'mail@example.com'] }

        include_examples 'the filter matches'
      end
    end

    context "with operator 'starts with one of'" do
      let(:operator) { 'starts with one of' }

      context 'with matching string' do
        let(:value) { ['daffy.duck', 'elmer.fudd'] }

        include_examples 'the filter matches'
      end

      context 'with matching upcased string' do
        let(:value) { ['Daffy.Duck', 'Elmer.Fudd'] }

        include_examples 'the filter matches'
      end

      context 'with non-matching string' do
        let(:value) { ['other.address', 'zammad.org'] }

        include_examples 'the filter does not match'
      end
    end

    context "with operator 'ends with one of'" do
      let(:operator) { 'ends with one of' }

      context 'with matching string' do
        let(:value) { ['acme.corp', 'example.com'] }

        include_examples 'the filter matches'
      end

      context 'with matching upcased string' do
        let(:value) { ['ACME.corp', 'EXAMPLE.com'] }

        include_examples 'the filter matches'
      end

      context 'with non-matching string' do
        let(:value) { ['example.com', 'zammad.org'] }

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
      expect(mail_hash['x-zammad-ticket-4206_datetime']).to eq(Time.zone.parse('2022-08-18T06:00:00.000Z'))
    end

    it 'does set values for 4206_date' do
      expect(mail_hash['x-zammad-ticket-4206_date']).to eq(Time.zone.parse('2022-08-19'))
    end
  end

  describe 'Trigger fails to set custom timestamp on report #4677', db_strategy: :reset do
    let(:field_name) { SecureRandom.uuid }

    let(:perform)           { {} }
    let(:postmaster_filter) { create(:postmaster_filter, perform: perform) }

    let(:perform_static) do
      { "x-zammad-ticket-#{field_name}" => { 'operator' => 'static', 'value' => '2023-07-18T06:00:00.000Z' } }
    end
    let(:perform_relative) do
      { "x-zammad-ticket-#{field_name}"=>{ 'operator' => 'relative', 'value' => '1', 'range' => 'day' } }
    end

    before do
      travel_to DateTime.new 2023, 0o7, 13, 10, 0o0
    end

    context 'when datetime' do
      before do
        create(:object_manager_attribute_datetime, object_name: 'Ticket', name: field_name, display: field_name)
        ObjectManager::Attribute.migration_execute
        postmaster_filter
        filter(mail_hash)
      end

      context 'when static' do
        let(:perform) { perform_static }

        it 'does set the value' do
          expect(mail_hash["x-zammad-ticket-#{field_name}"]).to eq(Time.zone.parse('2023-07-18T06:00:00.000Z'))
        end
      end

      context 'when relative' do
        let(:perform) { perform_relative }

        it 'does set the value' do
          expect(mail_hash["x-zammad-ticket-#{field_name}"]).to eq(1.day.from_now)
        end
      end
    end

    context 'when date' do
      before do
        create(:object_manager_attribute_date, object_name: 'Ticket', name: field_name, display: field_name)
        ObjectManager::Attribute.migration_execute
        postmaster_filter
        filter(mail_hash)
      end

      context 'when static' do
        let(:perform) { perform_static }

        it 'does set the value' do
          expect(mail_hash["x-zammad-ticket-#{field_name}"]).to eq(Time.zone.parse('2023-07-18'))
        end
      end

      context 'when relative' do
        let(:perform) { perform_relative }

        it 'does set the value' do
          expect(mail_hash["x-zammad-ticket-#{field_name}"]).to eq(1.day.from_now.to_date)
        end
      end
    end
  end

  describe 'Mail filter logs "contains not" instead of "contains" #5271', db_strategy: :reset do
    let(:postmaster_filter) do
      create(
        :postmaster_filter,
        match: {
          key => {
            'operator' => operator,
            'value'    => value,
          },
        },
      )
    end

    before do
      postmaster_filter
      allow(Rails.logger).to receive(:info)
      allow(Rails.logger).to receive(:debug)
      filter(mail_hash)
    end

    context 'with a matching contains operator' do
      let(:key)      { 'subject' }
      let(:operator) { 'contains' }
      let(:value)    { 'Anvil' }

      it 'logs info message', aggregate_failures: true do
        expect(Rails.logger).to have_received(:info).with(no_args) do |&block|
          expect(block.call).to match(%r{matching: key 'subject' contains 'Anvil'})
        end
      end
    end

    context 'with a matching contains not operator' do
      let(:key)      { 'from' }
      let(:operator) { 'contains not' }
      let(:value)    { 'buggs' }

      it 'logs info message', aggregate_failures: true do
        expect(Rails.logger).to have_received(:info).with(no_args) do |&block|
          expect(block.call).to match(%r{matching: key 'from' contains not 'buggs'})
        end
      end
    end

    context 'with a non matching contains operator' do
      let(:key)      { 'from' }
      let(:operator) { 'contains' }
      let(:value)    { 'buggs' }

      it 'logs debug messages', aggregate_failures: true do
        expect(Rails.logger).to have_received(:debug).twice.with(no_args) do |&block|
          expect(block.call).to match(%r{process filter}).or match(%r{not matching: key 'from' contains 'buggs'})
        end
      end
    end

    context 'with a non matching contains not operator' do
      let(:key)      { 'subject' }
      let(:operator) { 'contains not' }
      let(:value)    { 'Anvil' }

      it 'logs debug messages', aggregate_failures: true do
        expect(Rails.logger).to have_received(:debug).twice.with(no_args) do |&block|
          expect(block.call).to match(%r{process filter}).or match(%r{not matching: key 'subject' contains not 'Anvil'})
        end
      end
    end
  end
end
