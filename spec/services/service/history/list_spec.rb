# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::History::List, current_user_id: -> { user.id } do
  subject(:service) { described_class.new(current_user: user) }

  before do
    object
  end

  context 'when history object is a ticket' do
    let(:group)  { create(:group) }
    let(:object) { create(:ticket, group: group) }

    context 'when user is not authorized to view the ticket' do
      let(:user) { create(:agent) }

      it 'raises an error' do
        expect { service.execute(object:) }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context 'when user is authorized to view the ticket' do
      let(:user) { create(:agent, groups: [group]) }

      it 'returns a list of history events for the ticket', :aggregate_failures do
        expect { service.execute(object:) }.not_to raise_error
        expect(service.execute(object:)).to be_an_instance_of(Array)
        expect(service.execute(object:).first).to include(
          :created_at, :issuer, :action, :object, :attribute, :changes
        )
      end
    end
  end

  context 'when history object is a user' do
    let(:object) { create(:user) }

    context 'when user is not authorized to view the user' do
      let(:user) { create(:customer) }

      it 'raises an error' do
        expect { service.execute(object:) }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context 'when user is authorized to view the user' do
      let(:user) { create(:admin) }

      it 'returns a list of history events for the user', :aggregate_failures do
        expect { service.execute(object:) }.not_to raise_error
        expect(service.execute(object:)).to be_an_instance_of(Array)
        expect(service.execute(object:).first).to include(
          :created_at, :issuer, :action, :object, :attribute, :changes
        )
      end
    end
  end

  context 'when history object is a organization' do
    let(:object) { create(:organization) }

    context 'when user is not authorized to view the organization' do
      let(:user) { create(:customer) }

      it 'raises an error' do
        expect { service.execute(object:) }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context 'when user is authorized to view the organization' do
      let(:user) { create(:admin) }

      it 'returns a list of history events for the organization', :aggregate_failures do
        expect { service.execute(object:) }.not_to raise_error
        expect(service.execute(object:)).to be_an_instance_of(Array)
        expect(service.execute(object:).first).to include(
          :created_at, :issuer, :action, :object, :attribute, :changes
        )
      end
    end
  end
end
