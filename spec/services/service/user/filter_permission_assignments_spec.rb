# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::User::FilterPermissionAssignments do
  subject(:service) { described_class.new(current_user:) }

  let(:example_data) do
    { 'email' => 'some@example.com', 'role_ids' => [1, 2, 3], 'group_ids' => [1] }
  end

  context 'when user is admin' do
    let(:current_user) { create(:admin) }

    it 'keeps groups and roles' do
      data = example_data.deep_dup

      service.execute(user_data: data)

      expect(data).to eq(example_data)
    end

    it 'allows data to have no groups or roles' do
      data = example_data.slice('email')

      service.execute(user_data: data)

      expect(data).to eq(example_data.slice('email'))
    end
  end

  context 'when user is agent' do
    let(:current_user) { create(:agent) }

    it 'removes groups and roles' do
      data = example_data.deep_dup

      service.execute(user_data: data)

      expect(data).to eq(example_data.slice('email'))
    end

    it 'removes groups and roles with direct key name' do
      data = example_data.deep_dup.transform_keys { |key| key.sub('_ids', 's') }

      service.execute(user_data: data)

      expect(data).to eq(example_data.slice('email'))
    end

    it 'allows data to have no groups or roles' do
      data = example_data.slice('email')

      service.execute(user_data: data)

      expect(data).to eq(example_data.slice('email'))
    end
  end
end
