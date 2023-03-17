# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

DEFAULT_VALUES = {
  textarea: 'rspec',
  text:     'rspec',
  boolean:  true,
  date:     1,
  datetime: 12,
  integer:  123,
  select:   'key_1'
}.freeze

RSpec.describe ObjectManager::Attribute::SetDefaults, time_zone: 'Europe/London', type: :model do
  describe 'setting default', db_strategy: :reset_all do
    before :all do # rubocop:disable RSpec/BeforeAfterAll
      DEFAULT_VALUES.each do |key, value|
        create("object_manager_attribute_#{key}", name: "rspec_#{key}", default: value)
        create("object_manager_attribute_#{key}", name: "rspec_#{key}_no_default", default: nil)
      end

      create(:object_manager_attribute_text, name: 'rspec_empty', default: '')

      ObjectManager::Attribute.migration_execute
    end

    after :all do # rubocop:disable RSpec/BeforeAfterAll
      ObjectManager::Attribute.where('name LIKE ?', 'rspec_%').destroy_all
    end

    context 'with text type' do # on text
      it 'default value is set' do
        ticket = create(:ticket)
        expect(ticket.rspec_text).to eq 'rspec'
      end

      it 'empty string as default value gets saved' do
        ticket = create(:ticket)
        expect(ticket.rspec_empty).to eq ''
      end

      it 'given value overrides default value' do
        ticket = create(:ticket, rspec_text: 'another')
        expect(ticket.rspec_text).to eq 'another'
      end

      # actual create works slightly differently than FactoryGirl!
      it 'given value overrides default value when using native #create' do
        ticket_attrs            = attributes_for(:ticket, rspec_text: 'another', group: Group.first)
        ticket_attrs[:group]    = Group.first
        ticket_attrs[:customer] = User.first

        ticket_created = Ticket.create! ticket_attrs

        expect(ticket_created.rspec_text).to eq 'another'
      end

      it 'given nil overrides default value' do
        ticket = create(:ticket, rspec_text: nil)
        expect(ticket.rspec_text).to be_nil
      end

      it 'updating attribute to nil does not instantiate default' do
        ticket = create(:ticket)
        ticket.update! rspec_text: nil
        expect(ticket.rspec_text).to be_nil
      end
    end

    context 'when using other types' do
      subject(:example) { create(:ticket) }

      it 'boolean is set' do
        expect(example.rspec_boolean).to be true
      end

      it 'date is set' do
        freeze_time
        expect(example.rspec_date).to eq 1.day.from_now.to_date
      end

      it 'datetime is set' do
        travel_to Time.current.change(usec: 0, sec: 0)
        expect(example.rspec_datetime).to eq 12.hours.from_now
      end

      it 'integer is set' do
        expect(example.rspec_integer).to eq 123
      end

      it 'select value is set' do
        expect(example.rspec_select).to eq 'key_1'
      end

      context 'when system uses different time zone' do
        before do
          Setting.set('timezone_default', 'Europe/Vilnius')

          travel_to Time.current.change(hour: 23, usec: 0, sec: 0)
        end

        it 'date is set' do
          expect(example.rspec_date).to eq 2.days.from_now.to_date
        end

        it 'datetime is set' do
          expect(example.rspec_datetime).to eq 12.hours.from_now
        end
      end
    end

    context 'when overriding default to empty value' do
      subject(:example) do
        params = DEFAULT_VALUES.keys.each_with_object({}) { |elem, memo| memo["rspec_#{elem}"] = nil }
        create(:ticket, params)
      end

      DEFAULT_VALUES.each_key do |elem|
        it "#{elem} is empty" do
          expect(example.send("rspec_#{elem}")).to be_nil
        end
      end
    end

    context 'when default is not set' do
      subject(:example) { create(:ticket) }

      DEFAULT_VALUES.each_key do |elem|
        it "#{elem} is empty" do
          expect(example.send("rspec_#{elem}_no_default")).to be_nil
        end
      end
    end
  end
end
