# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Setting::Transformation::SanitizeHtml do
  let(:setting_name) { 'maintenance_login_message' }

  context 'when given value is blank' do
    it 'saves blank value' do
      expect { Setting.set(setting_name, '') }
        .to change { Setting.get(setting_name) }
        .to ''
    end
  end

  context 'when given value is nil' do
    it 'saves blank value' do
      expect { Setting.set(setting_name, nil) }
        .to change { Setting.get(setting_name) }
        .to ''
    end
  end

  context 'when given value is simple string' do
    it 'saves simple string' do
      expect { Setting.set(setting_name, '<b>text</b>') }
        .to change { Setting.get(setting_name) }
        .to '<b>text</b>'
    end
  end

  context 'when given value is complex html' do
    it 'saves simple string' do
      expect { Setting.set(setting_name, '<b>text</b> <img src="fish.jpg">') }
        .to change { Setting.get(setting_name) }
        .to '<b>text</b>'
    end
  end
end
