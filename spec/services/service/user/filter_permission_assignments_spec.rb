# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::User::FilterPermissionAssignments do
  subject(:service_result) { described_class.with_current_user(current_user).execute(user_data: data) }

  let(:example_data) do
    { 'email' => 'some@example.com', 'role_ids' => [1, 2, 3], 'group_ids' => [1] }
  end

  context 'when user is admin' do
    let(:current_user) { create(:admin) }

    context 'with full data' do
      let(:data) { example_data.deep_dup }

      it 'keeps groups and roles' do
        service_result

        expect(data).to eq(example_data)
      end
    end

    context 'with data having no groups or roles' do
      let(:data) { example_data.slice('email') }

      it 'allows data to have no groups or roles' do
        service_result

        expect(data).to eq(example_data.slice('email'))
      end
    end
  end

  context 'when user is agent' do
    let(:current_user) { create(:agent) }

    context 'with full data' do
      let(:data) { example_data.deep_dup }

      it 'removes groups and roles' do
        service_result

        expect(data).to eq(example_data.slice('email'))
      end
    end

    context 'with direct key names' do
      let(:data) { example_data.deep_dup.transform_keys { |key| key.sub('_ids', 's') } }

      it 'removes groups and roles with direct key name' do
        service_result

        expect(data).to eq(example_data.slice('email'))
      end
    end

    context 'with data having no groups or roles' do
      let(:data) { example_data.slice('email') }

      it 'allows data to have no groups or roles' do
        service_result

        expect(data).to eq(example_data.slice('email'))
      end
    end
  end
end
