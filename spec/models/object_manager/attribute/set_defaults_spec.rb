# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ObjectManager::Attribute::SetDefaults, type: :model do
  describe 'setting default', db_strategy: :reset_all do
    before :all do # rubocop:disable RSpec/BeforeAfterAll
      {
        text:     'rspec',
        boolean:  true,
        date:     1,
        datetime: 12,
        integer:  123,
        select:   'key_1'
      }.each do |key, value|
        create("object_manager_attribute_#{key}", name: "rspec_#{key}", default: value)
      end

      create('object_manager_attribute_text', name: 'rspec_empty', default: '')

      ObjectManager::Attribute.migration_execute
    end

    after :all do # rubocop:disable RSpec/BeforeAfterAll
      ObjectManager::Attribute.where('name LIKE ?', 'rspec_%').destroy_all
    end

    context 'with text type' do # on text
      it 'default value is set' do
        ticket = create :ticket
        expect(ticket.rspec_text).to eq 'rspec'
      end

      it 'empty string as default value gets saved' do
        ticket = create :ticket
        expect(ticket.rspec_empty).to eq ''
      end

      it 'given value overrides default value' do
        ticket = create :ticket, rspec_text: 'another'
        expect(ticket.rspec_text).to eq 'another'
      end

      # actual create works slightly differently than FactoryGirl!
      it 'given value overrides default value when using native #create' do
        ticket_attrs            = attributes_for :ticket, rspec_text: 'another', group: Group.first
        ticket_attrs[:group]    = Group.first
        ticket_attrs[:customer] = User.first

        ticket_created = Ticket.create! ticket_attrs

        expect(ticket_created.rspec_text).to eq 'another'
      end

      it 'given nil overrides default value' do
        ticket = create :ticket, rspec_text: nil
        expect(ticket.rspec_text).to be_nil
      end

      it 'updating attribute to nil does not instantiate default' do
        ticket = create :ticket
        ticket.update! rspec_text: nil
        expect(ticket.rspec_text).to be_nil
      end
    end

    context 'when using other types' do
      subject(:example) { create :ticket }

      it 'boolean is set' do
        expect(example.rspec_boolean).to eq true
      end

      it 'date is set' do
        freeze_time
        expect(example.rspec_date).to eq 1.day.from_now.to_date
      end

      it 'datetime is set' do
        freeze_time
        expect(example.rspec_datetime).to eq 12.hours.from_now
      end

      it 'integer is set' do
        expect(example.rspec_integer).to eq 123
      end

      it 'select value is set' do
        expect(example.rspec_select).to eq 'key_1'
      end
    end
  end
end
