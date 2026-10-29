# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe FormUpdater::ApplyValue::UserAutocomplete do
  describe '.resolve_option' do
    subject(:option) { described_class.resolve_option(id, current_user:) }

    let(:organization) { create(:organization) }
    let(:user)         { create(:agent, firstname: 'Jane', lastname: 'Doe', phone: '+49 123', organization:) }
    let(:id)           { user.id }

    context 'with an agent' do
      let(:current_user) { create(:agent) }

      it 'resolves the user with all fields' do
        expect(option).to include(
          value:   user.id,
          label:   'Jane Doe',
          heading: organization.name,
          object:  include('email' => user.email, 'phone' => '+49 123'),
        )
      end

      context 'when the id is not a plain number' do
        let(:id) { "#{user.id}abc" }

        it 'resolves nothing' do
          expect(option).to be_nil
        end
      end
    end

    context 'with a customer' do
      let(:current_user) { create(:customer, organization:) }

      it 'resolves no other user, not even of the own organization' do
        expect(option).to be_nil
      end

      context 'when resolving the own account' do
        let(:id) { current_user.id }

        it 'resolves the user' do
          expect(option).to include(value: current_user.id, object: include('email' => current_user.email))
        end
      end
    end
  end
end
