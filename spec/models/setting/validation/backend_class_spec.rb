# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Setting::Validation::BackendClass do
  let(:validated_settings) do
    Setting.all.select { |setting| Array(setting.preferences[:validations]).include?(described_class.name) }
  end

  it 'accepts the values of all validated settings', :aggregate_failures do
    rejected = validated_settings.filter_map do |setting|
      check = described_class.new(setting).check_value

      "#{setting.name}: #{check[:message]}" if !check[:success]
    end

    expect(validated_settings).to be_present
    expect(rejected).to be_empty
  end

  [
    ['auth_internal', { priority: 5, adapter: 'Auth::Backend::Internal' }],
    ['auth_developer', { adapter: 'Auth::Backend::Developer' }],
    ['auth_developer', {}],
    ['auth_ldap', nil],
    ['image_backend', ''],
    ['geo_location_backend', 'Service::GeoLocation::Osm'],
    ['ticket_number', 'Ticket::Number::Date'],
    ['import_backends', []],
    ['import_backends', ['Import::Ldap']],
    ['Stats::TicketReopen', 'Stats::TicketReopen'],
    ['0000_postmaster_filter_trusted', 'Channel::Filter::Trusted'],
    ['0100_notification', 'Transaction::Notification'],
  ].each do |name, value|
    it "accepts #{value.inspect} for #{name}" do
      expect { Setting.set(name, value) }.not_to raise_error
    end
  end

  [
    ['auth_internal', { priority: 1, adapter: 'Hashie::Mash' }, 'Hashie::Mash'],
    ['auth_ldap', { priority: 2, adapter: 'Auth::Backend::Base' }, 'Auth::Backend::Base'],
    ['auth_internal', { priority: 1, adapter: 'Auth::Backend::Developer' }, 'Auth::Backend::Developer'],
    ['image_backend', 'Service::Image::ClassMethods'],
    ['geo_ip_backend', 'KnowledgeBase::MenuItem'],
    ['ticket_number', 'JSON'],
    ['ticket_number', 'Ticket::Number::Base'],
    ['ticket_number', ''],
    ['import_backends', ['Import::Ldap', 'Hashie::Mash'], 'Hashie::Mash'],
    ['import_backends', ['Import::Zendesk'], 'Import::Zendesk'],
    ['Stats::TicketReopen', 'JSON'],
    ['Stats::TicketReopen', 'Stats::TicketEscalation'],
    ['0000_postmaster_filter_trusted', 'JSON'],
    ['0000_postmaster_filter_trusted', 'Channel::Filter::Database'],
    ['0006_postmaster_filter_auto_response_check', 'Channel::Filter::BaseIdentifyUser'],
    ['5401_postmaster_filter_jira_check', 'Channel::Filter::ServiceNowCheck'],
    ['0100_trigger', 'DataPrivacyTaskJob'],
    ['0100_trigger', 'Transaction::Notification'],
    ['0100_trigger', ''],
  ].each do |name, value, rejected = value|
    it "rejects #{value.inspect} for #{name}" do
      expect { Setting.set(name, value) }
        .to raise_error(ActiveRecord::RecordInvalid, %r{'#{Regexp.escape(rejected)}' is not a valid backend for this setting})
    end
  end

  [
    ['auth_internal', 'Auth::Backend::Internal'],
    ['auth_internal', { priority: 'x', adapter: 'Auth::Backend::Internal' }],
    ['ticket_number', ['Ticket::Number::Date']],
    ['import_backends', 'Import::Ldap'],
    ['Stats::TicketReopen', nil],
  ].each do |name, value|
    it "rejects the format of #{value.inspect} for #{name}" do
      expect { Setting.set(name, value) }
        .to raise_error(ActiveRecord::RecordInvalid, %r{The value of this setting has an invalid format})
    end
  end

  context 'with a stored value it rejects' do
    let(:setting) { Setting.find_by(name: 'ticket_number') }

    before { Setting.set('ticket_number', 'JSON', validate: false) }

    it 'checks the value only when it is changed', :aggregate_failures do
      expect { setting.update!(name: 'ticket_number_generator') }.not_to raise_error
      expect { setting.update!(state_current: { value: 'Ticket::Number::Base' }) }
        .to raise_error(ActiveRecord::RecordInvalid, %r{'Ticket::Number::Base' is not a valid backend for this setting})
    end
  end

  context 'with a setting an add-on registers in one of the areas' do
    let(:setting) do
      create(:setting,
             area:        'Postmaster::PreFilter',
             name:        '9999_postmaster_filter_addon',
             state:       'Channel::Filter::Database',
             preferences: { validations: [described_class.name] })
    end

    it 'accepts the backend it is created with and rejects any other one', :aggregate_failures do
      expect { setting }.not_to raise_error
      expect { Setting.set(setting.name, 'Channel::Filter::Trusted') }
        .to raise_error(ActiveRecord::RecordInvalid, %r{'Channel::Filter::Trusted' is not a valid backend for this setting})
    end
  end

  context 'with a setting outside of the known areas' do
    it 'rejects a value it offers no option for' do
      expect { create(:setting, state: 'Service::GeoIp::Zammad', preferences: { validations: [described_class.name] }) }
        .to raise_error(ActiveRecord::RecordInvalid, %r{'Service::GeoIp::Zammad' is not a valid backend for this setting})
    end
  end

  context 'with another setting of the Import area' do
    let(:setting) do
      create(:setting,
             area:        'Import',
             name:        'import_addon_backend',
             options:     { form: [{ options: { 'Import::Ldap' => 'LDAP' } }] },
             state:       'Import::Ldap',
             preferences: { validations: [described_class.name] })
    end

    it 'checks one class name against the options instead of a list', :aggregate_failures do
      expect { setting }.not_to raise_error
      expect { Setting.set(setting.name, ['Import::Ldap']) }
        .to raise_error(ActiveRecord::RecordInvalid, %r{The value of this setting has an invalid format})
      expect { Setting.set(setting.name, 'Import::Exchange') }
        .to raise_error(ActiveRecord::RecordInvalid, %r{'Import::Exchange' is not a valid backend for this setting})
    end
  end
end
