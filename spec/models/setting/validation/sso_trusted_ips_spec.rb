# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Setting::Validation::SsoTrustedIps do
  let(:setting_name) { 'auth_sso_trusted_ips' }

  context 'when value is valid' do
    it 'does not raise an error' do
      expect { Setting.set(setting_name, '192.168.1.1') }.not_to raise_error
    end
  end

  context 'when value contains an invalid entry' do
    it 'raises an error with the offending entry' do
      expect { Setting.set(setting_name, '192.168.1.1, not-an-ip') }
        .to raise_error(ActiveRecord::RecordInvalid, "Validation failed: 'not-an-ip' is not a valid IP address or CIDR range.")
    end
  end
end
