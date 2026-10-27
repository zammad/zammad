# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Seeded settings', type: :model do
  # SettingPolicy silently reserves a setting without a permission to full admins.
  it 'declare a permission or are protected' do
    undeclared = Setting.all.reject { |setting| setting.protected? || setting.preferences[:permission].present? }

    expect(undeclared.map(&:name)).to be_empty
  end
end
