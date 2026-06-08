# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

DEFAULT_VALUES = {
  textarea: 'rspec',
  text:     'rspec',
  boolean:  true,
  date:     24,  # in hours, so 1 day
  datetime: 720, # in minutes, so 12 hours
  integer:  123,
  select:   'key_1'
}.freeze

RSpec.describe ObjectManager::Attribute::SetDefaults, time_zone: 'Europe/London', type: :model do
  describe 'setting default', db_strategy: :reset do
    subject(:example) { create(:ticket) }

    def create_field(type, default: true, suffix: '')
      value = default ? DEFAULT_VALUES[type] : nil
      create("object_manager_attribute_#{type}", name: "rspec_#{type}#{suffix}", default: value)
    end

    context 'with text type' do # on text
      before do
        create_field(:text)
        create(:object_manager_attribute_text, name: 'rspec_empty', default: '')
        ObjectManager::Attribute.migration_execute
      end

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

    context 'when type is boolean' do
      before do
        create_field(:boolean)
        ObjectManager::Attribute.migration_execute
      end

      it { is_expected.to have_attributes(rspec_boolean: true) }
    end

    context 'when type is date' do
      before do
        freeze_time

        create_field(:date)
        ObjectManager::Attribute.migration_execute
      end

      it { is_expected.to have_attributes(rspec_date: 1.day.from_now.to_date) }

      context 'when system uses different time zone' do
        before do
          Setting.set('timezone_default', 'Europe/Vilnius')

          travel_to Time.current.change(hour: 23, usec: 0, sec: 0)
        end

        it { is_expected.to have_attributes(rspec_date: 2.days.from_now.to_date) }
      end

    end

    context 'when type is datetime' do
      before do
        travel_to Time.current.change(usec: 0, sec: 0)
        create_field(:datetime)
        ObjectManager::Attribute.migration_execute
      end

      it { is_expected.to have_attributes(rspec_datetime: 12.hours.from_now) }

      context 'when system uses different time zone' do
        before do
          Setting.set('timezone_default', 'Europe/Vilnius')

          travel_to Time.current.change(hour: 23, usec: 0, sec: 0)
        end

        it { is_expected.to have_attributes(rspec_datetime: 12.hours.from_now) }
      end

    end

    context 'when type is integer' do
      before do
        create_field(:integer)
        ObjectManager::Attribute.migration_execute
      end

      it { is_expected.to have_attributes(rspec_integer: 123) }
    end

    context 'when type is select' do
      before do
        create_field(:select)
        ObjectManager::Attribute.migration_execute
      end

      it { is_expected.to have_attributes(rspec_select: 'key_1') }
    end

    context 'when overriding default to empty value' do
      DEFAULT_VALUES.each_key do |elem|
        context "when using #{elem} type" do
          subject(:example) { create(:ticket, "rspec_#{elem}" => nil) }

          before do
            create_field(elem)
            ObjectManager::Attribute.migration_execute
          end

          it { is_expected.to have_attributes("rspec_#{elem}": nil) }
        end
      end
    end

    context 'when default is not set' do
      subject(:example) { create(:ticket) }

      DEFAULT_VALUES.each_key do |elem|
        context "when using #{elem} type" do
          before do
            create_field(elem, default: false, suffix: '_no_default')
            ObjectManager::Attribute.migration_execute
          end

          it "#{elem} is empty" do
            expect(example.send(:"rspec_#{elem}_no_default")).to be_nil
          end
        end
      end
    end

    # https://github.com/zammad/zammad/issues/5666
    context 'with external data source type' do
      before do
        create(:object_manager_attribute_autocompletion_ajax_external_data_source, name: 'rspec_external_data_source')
        ObjectManager::Attribute.migration_execute
      end

      it 'saves correctly as an empty hash' do
        ticket = create(:ticket)

        expect(ticket.reload.rspec_external_data_source).to eq({})
      end

      it 'initializes correctly as an empty hash' do
        ticket = build(:ticket)

        expect(ticket.rspec_external_data_source).to eq({})
      end
    end
  end
end
