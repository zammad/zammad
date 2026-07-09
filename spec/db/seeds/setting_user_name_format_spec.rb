# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

RSpec.describe 'Setting user_name_format', type: :model do
  subject(:setting) { Setting.find_by(name: 'user_name_format') }

  it 'exists' do
    expect(setting).to be_present
  end

  it 'has default value first_last' do
    expect(Setting.get('user_name_format')).to eq('first_last')
  end

  it 'is in System::Branding area' do
    expect(setting.area).to eq('System::Branding')
  end

  it 'is exposed to frontend' do
    expect(setting.frontend).to be(true)
  end

  it 'has select options with all three formats' do
    options = setting.options[:form].first[:options]
    expect(options.keys).to match_array(%w[first_last last_first last_first_comma])
  end

  it 'has admin.branding permission' do
    expect(setting.preferences[:permission]).to include('admin.branding')
  end

  it 'has valid state_initial' do
    expect(setting.state_initial[:value]).to eq('first_last')
  end
end
