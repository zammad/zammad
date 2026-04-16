# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe FilterProcessor, type: :channel_filter do
  subject(:instance) { described_class.new(filter, mail_hash) }

  let(:mail_hash) { Channel::EmailParser.new.parse(<<~RAW.chomp) }
    From: daffy.duck@acme.corp
    To: batman@marvell.com
    Subject: Anvil

    I can haz anvil!
  RAW

  describe '#filter_matches?' do
    context 'with no match rules' do
      let(:filter) { build(:postmaster_filter, match: {}) }

      it 'returns false' do
        expect(described_class.new(filter, mail_hash).filter_matches?).to be false
      end
    end

    context 'with blank condition value' do
      let(:filter) { build(:postmaster_filter, match: { 'from' => { 'operator' => 'contains', 'value' => '' } }) }

      it 'skips the condition and returns false' do
        expect(described_class.new(filter, mail_hash).filter_matches?).to be false
      end
    end

    context 'with a matching condition' do
      let(:filter) { create(:postmaster_filter, match: { 'from' => { 'operator' => 'contains', 'value' => 'daffy' } }) }

      it 'returns true' do
        expect(described_class.new(filter, mail_hash).filter_matches?).to be true
      end
    end

    context 'with a non-matching condition' do
      let(:filter) { create(:postmaster_filter, match: { 'from' => { 'operator' => 'contains', 'value' => 'bugs.bunny' } }) }

      it 'returns false' do
        expect(described_class.new(filter, mail_hash).filter_matches?).to be false
      end
    end

    context 'with multiple conditions (AND semantics)' do
      context 'when all match' do
        let(:filter) do
          create(:postmaster_filter, match: {
                   'from'    => { 'operator' => 'contains', 'value' => 'daffy' },
                   'subject' => { 'operator' => 'contains', 'value' => 'Anvil' },
                 })
        end

        it 'returns true' do
          expect(described_class.new(filter, mail_hash).filter_matches?).to be true
        end
      end

      context 'when one does not match' do
        let(:filter) do
          create(:postmaster_filter, match: {
                   'from'    => { 'operator' => 'contains', 'value' => 'daffy' },
                   'subject' => { 'operator' => 'contains', 'value' => 'Hammer' },
                 })
        end

        it 'returns false' do
          expect(described_class.new(filter, mail_hash).filter_matches?).to be false
        end
      end
    end

    context 'with an invalid operator' do
      let(:filter) { build(:postmaster_filter, match: { 'from' => { 'operator' => 'bogus_operator', 'value' => 'daffy' } }) }

      it 'returns false' do
        expect(described_class.new(filter, mail_hash).filter_matches?).to be false
      end
    end

    context "with operator 'contains not'" do
      context 'when value matches' do
        let(:filter) { create(:postmaster_filter, match: { 'from' => { 'operator' => 'contains not', 'value' => 'daffy' } }) }

        it 'returns false' do
          expect(described_class.new(filter, mail_hash).filter_matches?).to be false
        end
      end

      context 'when value does not match' do
        let(:filter) { create(:postmaster_filter, match: { 'from' => { 'operator' => 'contains not', 'value' => 'bugs' } }) }

        it 'returns true' do
          expect(described_class.new(filter, mail_hash).filter_matches?).to be true
        end
      end
    end

    context "with operator 'matches regex'" do
      context 'when regex matches' do
        let(:filter) { create(:postmaster_filter, match: { 'from' => { 'operator' => 'matches regex', 'value' => 'daffy\.duck@.*' } }) }

        it 'returns true' do
          expect(described_class.new(filter, mail_hash).filter_matches?).to be true
        end
      end

      context 'when regex does not match' do
        let(:filter) { create(:postmaster_filter, match: { 'from' => { 'operator' => 'matches regex', 'value' => 'bugs\.bunny@.*' } }) }

        it 'returns false' do
          expect(described_class.new(filter, mail_hash).filter_matches?).to be false
        end
      end
    end

    context "with operator 'does not match regex'" do
      context 'when regex matches' do
        let(:filter) { create(:postmaster_filter, match: { 'from' => { 'operator' => 'does not match regex', 'value' => 'daffy\.duck@.*' } }) }

        it 'returns false' do
          expect(described_class.new(filter, mail_hash).filter_matches?).to be false
        end
      end

      context 'when regex does not match' do
        let(:filter) { create(:postmaster_filter, match: { 'from' => { 'operator' => 'does not match regex', 'value' => 'bugs\.bunny@.*' } }) }

        it 'returns true' do
          expect(described_class.new(filter, mail_hash).filter_matches?).to be true
        end
      end
    end

    context "with operator 'is any of'" do
      context 'when value is in list' do
        let(:filter) { create(:postmaster_filter, match: { 'from' => { 'operator' => 'is any of', 'value' => ['daffy.duck@acme.corp', 'elmer.fudd@acme.corp'] } }) }

        it 'returns true' do
          expect(described_class.new(filter, mail_hash).filter_matches?).to be true
        end
      end

      context 'when value is not in list' do
        let(:filter) { create(:postmaster_filter, match: { 'from' => { 'operator' => 'is any of', 'value' => ['bugs.bunny@acme.corp', 'elmer.fudd@acme.corp'] } }) }

        it 'returns false' do
          expect(described_class.new(filter, mail_hash).filter_matches?).to be false
        end
      end
    end

    context "with operator 'is none of'" do
      context 'when value is in list' do
        let(:filter) { create(:postmaster_filter, match: { 'from' => { 'operator' => 'is none of', 'value' => ['daffy.duck@acme.corp', 'elmer.fudd@acme.corp'] } }) }

        it 'returns false' do
          expect(described_class.new(filter, mail_hash).filter_matches?).to be false
        end
      end

      context 'when value is not in list' do
        let(:filter) { create(:postmaster_filter, match: { 'from' => { 'operator' => 'is none of', 'value' => ['bugs.bunny@acme.corp', 'elmer.fudd@acme.corp'] } }) }

        it 'returns true' do
          expect(described_class.new(filter, mail_hash).filter_matches?).to be true
        end
      end
    end

    context "with operator 'starts with one of'" do
      context 'when value starts with entry' do
        let(:filter) { create(:postmaster_filter, match: { 'from' => { 'operator' => 'starts with one of', 'value' => %w[daffy elmer] } }) }

        it 'returns true' do
          expect(described_class.new(filter, mail_hash).filter_matches?).to be true
        end
      end

      context 'when value does not start with any entry' do
        let(:filter) { create(:postmaster_filter, match: { 'from' => { 'operator' => 'starts with one of', 'value' => %w[bugs elmer] } }) }

        it 'returns false' do
          expect(described_class.new(filter, mail_hash).filter_matches?).to be false
        end
      end
    end

    context "with operator 'ends with one of'" do
      context 'when value ends with entry' do
        let(:filter) { create(:postmaster_filter, match: { 'from' => { 'operator' => 'ends with one of', 'value' => ['acme.corp', 'example.com'] } }) }

        it 'returns true' do
          expect(described_class.new(filter, mail_hash).filter_matches?).to be true
        end
      end

      context 'when value does not end with any entry' do
        let(:filter) { create(:postmaster_filter, match: { 'from' => { 'operator' => 'ends with one of', 'value' => ['example.com', 'zammad.org'] } }) }

        it 'returns false' do
          expect(described_class.new(filter, mail_hash).filter_matches?).to be false
        end
      end
    end

    context 'with regex named captures' do
      let(:filter) { create(:postmaster_filter, match: { 'from' => { 'operator' => 'matches regex', 'value' => '(?<user>.+)@(?<domain>.+)' } }) }

      it 'stores named and numbered captures in context' do
        processor = described_class.new(filter, mail_hash)
        processor.filter_matches?
        expect(processor.context[:match_data]).to include(
          '1'      => 'daffy.duck',
          '2'      => 'acme.corp',
          'user'   => 'daffy.duck',
          'domain' => 'acme.corp',
        )
      end
    end

    context 'with regex unnamed captures' do
      let(:filter) { create(:postmaster_filter, match: { 'from' => { 'operator' => 'matches regex', 'value' => '(.+)@(.+)' } }) }

      it 'stores numbered captures in context' do
        processor = described_class.new(filter, mail_hash)
        processor.filter_matches?
        expect(processor.context[:match_data]).to include(
          '1' => 'daffy.duck',
          '2' => 'acme.corp',
        )
      end
    end
  end

  describe '#process' do
    context 'with single named capture substitution' do
      let(:ticket_id)  { Faker::Number.unique.number(digits: 5).to_s }
      let(:from_email) { Faker::Internet.unique.email }
      let(:to_email)   { Faker::Internet.unique.email }

      let(:filter) do
        create(:postmaster_filter,
               match:   { 'subject' => { 'operator' => 'matches regex', 'value' => '(?<ticket_id>\\d+)' } },
               perform: { 'x-zammad-ticket-title' => { 'value' => 'External: #{regexp.ticket_id}' } }) # rubocop:disable Lint/InterpolationCheck
      end

      let(:process_mail) { Channel::EmailParser.new.parse(<<~RAW.chomp) }
        From: #{from_email}
        To: #{to_email}
        Subject: [EXT-#{ticket_id}] #{Faker::Lorem.word}

        #{Faker::Lorem.sentence}
      RAW

      it 'replaces #{regexp.NAME} placeholders in perform values' do # rubocop:disable Lint/InterpolationCheck
        described_class.new(filter, process_mail).process
        expect(process_mail[:'x-zammad-ticket-title']).to eq("External: #{ticket_id}")
      end
    end

    context 'when the same filter instance is applied to successive emails' do
      let(:perform_template) { 'External: #{regexp.ticket_id}' } # rubocop:disable Lint/InterpolationCheck
      let(:ticket_id_first)  { Faker::Number.unique.number(digits: 5).to_s }
      let(:ticket_id_second) { Faker::Number.unique.number(digits: 5).to_s }
      let(:from_email)       { Faker::Internet.unique.email }
      let(:to_email)         { Faker::Internet.unique.email }

      let(:filter) do
        create(:postmaster_filter,
               match:   { 'subject' => { 'operator' => 'matches regex', 'value' => '(?<ticket_id>\\d+)' } },
               perform: { 'x-zammad-ticket-title' => { 'value' => perform_template } })
      end

      let(:mail_with_ticket_id) do
        lambda do |ticket_id|
          Channel::EmailParser.new.parse(<<~RAW.chomp)
            From: #{from_email}
            To: #{to_email}
            Subject: [EXT-#{ticket_id}] #{Faker::Lorem.word}

            #{Faker::Lorem.sentence}
          RAW
        end
      end

      let(:first_mail)  { mail_with_ticket_id.call(ticket_id_first) }
      let(:second_mail) { mail_with_ticket_id.call(ticket_id_second) }

      it 'substitutes captures per email without mutating stored perform values' do
        described_class.new(filter, first_mail).process
        described_class.new(filter, second_mail).process
        expect(
          first_mail_title:  first_mail[:'x-zammad-ticket-title'],
          second_mail_title: second_mail[:'x-zammad-ticket-title'],
          perform_value:     filter.perform['x-zammad-ticket-title']['value'],
        ).to eq(
          first_mail_title:  "External: #{ticket_id_first}",
          second_mail_title: "External: #{ticket_id_second}",
          perform_value:     perform_template,
        )
      end
    end

    context 'with multiple captures from multiple conditions' do
      let(:sender_local) { Faker::Internet.unique.username }
      let(:sender_domain) { Faker::Internet.unique.domain_name }
      let(:ref_prefix)    { Faker::Alphanumeric.unique.alpha(number: 3).upcase }
      let(:ref_number)    { Faker::Number.unique.number(digits: 3).to_s }
      let(:ref)           { "#{ref_prefix}-#{ref_number}" }

      let(:filter) do
        create(:postmaster_filter,
               match:   {
                 'from'    => { 'operator' => 'matches regex', 'value' => '(?<sender>.+)@' },
                 'subject' => { 'operator' => 'matches regex', 'value' => '\\[(?<ref>[A-Z]+-\\d+)\\]' },
               },
               perform: { 'x-zammad-ticket-title' => { 'value' => '#{regexp.ref} from #{regexp.sender}' } }) # rubocop:disable Lint/InterpolationCheck
      end

      let(:process_mail) { Channel::EmailParser.new.parse(<<~RAW.chomp) }
        From: #{sender_local}@#{sender_domain}
        To: #{Faker::Internet.unique.email}
        Subject: [#{ref}] #{Faker::Lorem.word}

        #{Faker::Lorem.sentence}
      RAW

      it 'replaces placeholders from multiple conditions' do
        described_class.new(filter, process_mail).process
        expect(process_mail[:'x-zammad-ticket-title']).to eq("#{ref} from #{sender_local}")
      end
    end

    context 'with unmatched placeholder' do
      let(:filter) do
        create(:postmaster_filter,
               match:   { 'from' => { 'operator' => 'matches regex', 'value' => '(?<user>.+)@' } },
               perform: { 'x-zammad-ticket-title' => { 'value' => '#{regexp.user} #{regexp.missing}' } }) # rubocop:disable Lint/InterpolationCheck
      end

      it 'replaces unmatched placeholders with dash' do
        described_class.new(filter, mail_hash).process
        expect(mail_hash[:'x-zammad-ticket-title']).to eq('daffy.duck -')
      end
    end
  end

  describe 'Cannot set date for pending close status in postmaster filter #4206', db_strategy: :reset do
    let(:filter) do
      create(:postmaster_filter, perform: {
               'x-zammad-ticket-pending_time'  => { 'operator' => 'relative', 'value' => '12', 'range' => 'minute' },
               'x-zammad-ticket-state_id'      => { 'value' => Ticket::State.find_by(name: 'pending reminder').id },
               'x-zammad-ticket-4206_datetime' => { 'operator' => 'static', 'value' => '2022-08-18T06:00:00.000Z' },
               'x-zammad-ticket-4206_date'     => { 'value' => '2022-08-19' }
             })
    end

    before do
      freeze_time

      create(:object_manager_attribute_date, name: '4206_date')
      create(:object_manager_attribute_datetime, name: '4206_datetime')
      ObjectManager::Attribute.migration_execute
      instance.process
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
    let(:filter)     { create(:postmaster_filter, perform: perform) }

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
        instance.process
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
        instance.process
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
    let(:filter) do
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
      allow(Rails.logger).to receive(:info)
      allow(Rails.logger).to receive(:debug)
      instance.process
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
        expect(Rails.logger).to have_received(:debug).with(no_args) do |&block|
          expect(block.call).to match(%r{not matching: key 'from' contains 'buggs'})
        end
      end
    end

    context 'with a non matching contains not operator' do
      let(:key)      { 'subject' }
      let(:operator) { 'contains not' }
      let(:value)    { 'Anvil' }

      it 'logs debug messages', aggregate_failures: true do
        expect(Rails.logger).to have_received(:debug).with(no_args) do |&block|
          expect(block.call).to match(%r{not matching: key 'subject' contains not 'Anvil'})
        end
      end
    end
  end

  describe 'postmaster filter with regex' do
    let(:mail_hash) { Channel::EmailParser.new.parse(<<~RAW.chomp) }
      From: daffy.duck@acme.corp
      To: batman@marvell.com
      Subject: Anvil

      Customers Formular Message is:

      ContractID: 1234abcd
      CustomerEmail: customer@example.com
    RAW

    let(:filter) do
      create(:postmaster_filter,
             match:   { 'body' => { 'operator' => 'matches regex', 'value' => regex_value } },
             perform: { 'x-zammad-ticket-title' => { 'value' => target_value } },
             channel: 'email',
             active:  true)
    end

    context 'when the filter uses a named capture group' do
      let(:regex_value)  { 'ContractID:\s(?<CONTRACT_ID>.*)' }
      let(:target_value) { '#{regexp.CONTRACT_ID}' } # rubocop:disable Lint/InterpolationCheck

      it 'sets the ticket title using the captured CONTRACT_ID' do
        instance.process
        expect(mail_hash[:'x-zammad-ticket-title']).to eq('1234abcd')
      end
    end

    context 'when the filter uses a regex with nameless capture groups' do
      let(:regex_value)  { 'ContractID:\s(.*)' }
      let(:target_value) { '#{regexp.1}' }

      it 'sets the ticket title using the captured CONTRACT_ID' do
        instance.process
        expect(mail_hash[:'x-zammad-ticket-title']).to eq('1234abcd')
      end
    end

    context 'when the filter finds no value in question' do
      let(:regex_value)  { 'ContractID:\s(.*)' }
      let(:target_value) { '#{regexp.CONTRAKT}' } # rubocop:disable Lint/InterpolationCheck

      it 'sets the ticket title using fallback value' do
        instance.process
        expect(mail_hash[:'x-zammad-ticket-title']).to eq('-')
      end
    end
  end
end
