# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Setting::Validation::TimeZone do
  let(:setting_name) { 'timezone_default' }

  context 'when given value is blank' do
    it 'does raise an error' do
      expect { Setting.set(setting_name, '') }
        .to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Time zone is required.')
    end
  end

  context 'when given value is non-existant identifier' do
    it 'does raise an error' do
      expect { Setting.set(setting_name, 'blablabla') }
        .to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Given time zone is not valid.')
    end
  end

  context 'when given value is valid time zone identifier' do
    it 'does not raise an error' do
      expect { Setting.set(setting_name, 'UTC') }.not_to raise_error
    end
  end
end
