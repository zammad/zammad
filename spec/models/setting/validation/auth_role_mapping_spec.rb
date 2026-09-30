# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Setting::Validation::AuthRoleMapping do
  let(:setting_name) { 'auth_openid_connect_credentials' }

  def role_mapping(value)
    { 'identifier' => 'zammad', 'role_mapping' => value }
  end

  context 'when value is blank' do
    it 'does not raise an error' do
      expect { Setting.set(setting_name, role_mapping({})) }.not_to raise_error
    end
  end

  context 'when value is valid' do
    it 'does not raise an error' do
      expect { Setting.set(setting_name, role_mapping({ 'attribute' => 'Role', 'map' => { 'zammad-agent' => ['2', 3] }, 'unmatched' => 'deny' })) }.not_to raise_error
    end
  end

  context 'when value is not an object' do
    it 'raises an error' do
      expect { Setting.set(setting_name, role_mapping('Role')) }
        .to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: The role mapping has to be an object.')
    end
  end

  context 'when the attribute is not a text' do
    it 'raises an error' do
      expect { Setting.set(setting_name, role_mapping({ 'attribute' => ['Role'], 'map' => { 'zammad-agent' => ['2'] } })) }
        .to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: The role mapping attribute has to be a text.')
    end
  end

  context 'when the map contains an invalid role ID' do
    it 'raises an error' do
      expect { Setting.set(setting_name, role_mapping({ 'attribute' => 'Role', 'map' => { 'zammad-agent' => ['Agent'] } })) }
        .to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: The role mapping needs a map of values to role IDs.')
    end
  end

  context 'when a mapped value has no role' do
    it 'raises an error' do
      expect { Setting.set(setting_name, role_mapping({ 'attribute' => 'Role', 'map' => { 'zammad-agent' => [] } })) }
        .to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Each role mapping needs a value and at least one role.')
    end
  end

  context 'when roles are mapped to an empty value' do
    it 'raises an error' do
      expect { Setting.set(setting_name, role_mapping({ 'attribute' => 'Role', 'map' => { ' ' => [2] } })) }
        .to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Each role mapping needs a value and at least one role.')
    end
  end

  context 'when the behavior for logins without a mapped role is unknown' do
    it 'raises an error' do
      expect { Setting.set(setting_name, role_mapping({ 'attribute' => 'Role', 'map' => {}, 'unmatched' => 'keep' })) }
        .to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: The behavior for logins without a mapped role is not supported.')
    end
  end
end
