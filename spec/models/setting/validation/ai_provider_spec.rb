# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Setting::Validation::AIProvider do

  let(:setting_name) { 'ai_provider' }

  context 'with blank settings' do
    it 'does not raise error' do
      expect { Setting.set(setting_name, '') }.not_to raise_error
    end
  end

  context 'with unsupported provider' do
    it 'raises error' do
      expect { Setting.set(setting_name, 'unsupported') }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  context 'with supported provider' do
    it 'does not raise error' do
      expect { Setting.set(setting_name, 'open_ai') }.not_to raise_error
    end
  end
end
