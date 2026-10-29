# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe SettingBackendClassValidation, type: :db_migration do
  let(:validation) { 'Setting::Validation::BackendClass' }
  let(:validated_names) do
    Setting.all.select { |setting| Array(setting.preferences[:validations]).include?(validation) }.map(&:name)
  end

  # The seeds already attach the validation, so it is removed first and expected back afterwards.
  let!(:validated_by_seeds) { validated_names }

  before do
    Setting.find_each do |setting|
      next if Array(setting.preferences[:validations]).exclude?(validation)

      setting.update!(preferences: setting.preferences.except(:validations))
    end
  end

  it 'adds the backend class validation to every setting naming a backend class' do
    migrate

    expect(validated_names).to match_array(validated_by_seeds)
  end

  it 'adds it to a setting an add-on registered in one of the areas' do
    create(:setting, area: 'Dashboard::Stats', name: 'Stats::AddonBackend', state: 'Stats::TicketReopen')

    expect { migrate }.to change { Setting.find_by(name: 'Stats::AddonBackend').preferences[:validations] }.to([validation])
  end

  it 'keeps a stored value the validation rejects and logs it', :aggregate_failures do
    Setting.set('ticket_number', 'JSON')
    allow(Rails.logger).to receive(:warn)

    expect { migrate }.not_to change { Setting.get('ticket_number') }
    expect(Rails.logger).to have_received(:warn).with(%r{Setting 'ticket_number' keeps a value its new validation rejects: 'JSON' is not a valid backend})
  end

  {
    '0000_postmaster_filter_trusted' => ['Channel::Filter::Database', 'Channel::Filter::Trusted'],
    'Stats::TicketReopen'            => ['JSON', 'Stats::TicketReopen'],
    'auth_internal'                  => [{ priority: 1, adapter: 'Hashie::Mash' }, { 'priority' => 1, 'adapter' => 'Auth::Backend::Internal' }],
  }.each do |name, (stored, initial)|
    it "resets #{name} from #{stored.inspect} to the backend it registers and logs it", :aggregate_failures do
      Setting.set(name, stored)
      allow(Rails.logger).to receive(:warn)

      expect { migrate }.to change { Setting.get(name) }.to(initial)
      expect(Rails.logger).to have_received(:warn).with(%r{Setting '#{Regexp.escape(name)}' is reset to its initial value, as its new validation rejects the stored one})
    end
  end

  context 'with the bounce follow-up filter of a system from before its class was renamed' do
    let(:setting) { Setting.find_by(name: '0900_postmaster_filter_bounce_follow_up_check') }

    before do
      setting.update!(state_initial: { value: 'Channel::Filter::BounceCheck' })
      allow(Rails.logger).to receive(:warn)
    end

    it 'realigns the initial value with the renamed class', :aggregate_failures do
      expect { migrate }.to change { setting.reload.state_initial[:value] }.to('Channel::Filter::BounceFollowUpCheck')
      expect(Setting.get(setting.name)).to eq('Channel::Filter::BounceFollowUpCheck')
      expect(Rails.logger).not_to have_received(:warn).with(%r{Setting '#{setting.name}'})
    end

    it 'resets a stored value the realigned initial value rejects', :aggregate_failures do
      Setting.set(setting.name, 'Channel::Filter::Database', validate: false)

      expect { migrate }.to change { Setting.get(setting.name) }.to('Channel::Filter::BounceFollowUpCheck')
      expect(setting.reload.state_initial[:value]).to eq('Channel::Filter::BounceFollowUpCheck')
      expect(Rails.logger).to have_received(:warn).with(%r{Setting '#{setting.name}' is reset to its initial value})
    end
  end

  context 'with a pre filter an add-on registered outside Channel::Filter' do
    before do
      create(:setting, area: 'Postmaster::PreFilter', name: '0500_postmaster_filter_addon', state: 'JSON')
      allow(Rails.logger).to receive(:warn)
    end

    it 'keeps the value and logs that it does not load', :aggregate_failures do
      expect { migrate }.not_to change { Setting.get('0500_postmaster_filter_addon') }.from('JSON')
      expect(Setting.find_by(name: '0500_postmaster_filter_addon').preferences[:validations]).to eq(['Setting::Validation::BackendClass'])
      expect(Rails.logger).to have_received(:warn).with(%r{Setting '0500_postmaster_filter_addon' registers 'JSON', which the code using it can't load})
    end
  end

  it 'leaves new systems to the seeds', system_init_done: false do
    expect { migrate }.not_to change { Setting.find_by(name: 'ticket_number').preferences[:validations] }.from(nil)
  end
end
