# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::History::List, current_user_id: -> { user.id } do
  before do
    object
  end

  context 'when history object is a ticket' do
    let(:group)  { create(:group) }
    let(:object) { create(:ticket, group: group) }

    context 'when user is not authorized to view the ticket' do
      subject(:service_result) { described_class.with_current_user(user).execute(object:) }

      let(:user) { create(:agent) }

      it 'raises an error' do
        expect { service_result }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context 'when user is authorized to view the ticket' do
      subject(:service_result) { described_class.with_current_user(user).execute(object:) }

      let(:user) { create(:agent, groups: [group]) }

      it 'returns a list of history events for the ticket', :aggregate_failures do
        expect { service_result }.not_to raise_error
        expect(service_result).to be_an_instance_of(Array)
        expect(service_result.first).to include(
          :created_at, :issuer, :action, :object, :attribute, :changes
        )
      end
    end
  end

  context 'when history object is a user' do
    let(:object) { create(:user) }

    context 'when user is not authorized to view the user' do
      subject(:service_result) { described_class.with_current_user(user).execute(object:) }

      let(:user) { create(:customer) }

      it 'raises an error' do
        expect { service_result }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context 'when user is authorized to view the user' do
      subject(:service_result) { described_class.with_current_user(user).execute(object:) }

      let(:user) { create(:admin) }

      it 'returns a list of history events for the user', :aggregate_failures do
        expect { service_result }.not_to raise_error
        expect(service_result).to be_an_instance_of(Array)
        expect(service_result.first).to include(
          :created_at, :issuer, :action, :object, :attribute, :changes
        )
      end
    end
  end

  context 'when history object is a organization' do
    let(:object) { create(:organization) }

    context 'when user is not authorized to view the organization' do
      subject(:service_result) { described_class.with_current_user(user).execute(object:) }

      let(:user) { create(:customer) }

      it 'raises an error' do
        expect { service_result }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context 'when user is authorized to view the organization' do
      subject(:service_result) { described_class.with_current_user(user).execute(object:) }

      let(:user) { create(:admin) }

      it 'returns a list of history events for the organization', :aggregate_failures do
        expect { service_result }.not_to raise_error
        expect(service_result).to be_an_instance_of(Array)
        expect(service_result.first).to include(
          :created_at, :issuer, :action, :object, :attribute, :changes
        )
      end
    end
  end
end
