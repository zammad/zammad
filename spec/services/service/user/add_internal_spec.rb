# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::User::AddInternal do
  subject(:service) { described_class.new(current_user:) }

  let(:current_user)    { create(:admin) }
  let(:send_invite)     { false }
  let(:user_data_email) { 'dummy@zammad.com' }
  let(:user_data) do
    {
      email:     user_data_email,
      firstname: 'Bender',
      lastname:  'Rodríguez',
    }
  end

  describe 'creating a user' do
    it 'creates a user with valid data' do
      user = service.execute(user_data:)

      expect(user)
        .to be_persisted
        .and(have_attributes(**user_data))
    end

    it 'sets default roles' do
      user = service.execute(user_data:)

      expect(user.roles).to match_array(Role.find_by(name: 'Customer'))
    end

    it 'creates a user with given roles' do
      user_data[:roles] = [Role.find_by(name: 'Admin')]
      user = service.execute(user_data:)

      expect(user.roles).to match_array(Role.find_by(name: 'Admin'))
    end

    context 'with non-admin user' do
      let(:current_user) { create(:agent) }

      it 'filters sensitive inputs' do
        user_data[:roles] = [Role.find_by(name: 'Admin')]
        user = service.execute(user_data:)

        expect(user.roles).to match_array(Role.find_by(name: 'Customer'))
      end
    end

    it 'raises an error if email is already taken' do
      existing_user = create(:user)

      user_data[:email] = existing_user.email

      expect { service.execute(user_data:) }
        .to raise_error(
          ActiveRecord::RecordInvalid,
          "Validation failed: Email address '#{existing_user.email}' is already used for another user."
        )
    end

    it 'creates an email-less user' do
      user_data[:email] = nil

      user = service.execute(user_data:)

      expect(user)
        .to be_persisted
        .and(have_attributes(**user_data))
    end

    it 'creates a user with the given groups access' do
      group = create(:group)

      user_data[:roles] = [Role.find_by(name: 'Agent')] # ticket.agent is required for group access
      user_data[:group_ids_access_map] = { group.id => %w[read change] }

      user = service.execute(user_data:)

      expect(user.group_ids_access_map).to include(group.id => match_array(%w[read change]))
    end
  end

  describe 'sending invite email' do
    before do
      allow(NotificationFactory::Mailer).to receive(:notification)
    end

    context 'when send_invite is true' do
      let(:send_invite) { true }

      it 'sends invite' do
        service.execute(user_data:, send_invite:)

        expect(NotificationFactory::Mailer)
          .to have_received(:notification)
          .with(include(user: have_attributes(email: user_data_email)))
      end

      context 'when user is email-less' do
        it 'does not send invite' do
          user_data.delete :email

          service.execute(user_data:, send_invite:)

          expect(NotificationFactory::Mailer)
            .not_to have_received(:notification)
        end
      end
    end

    context 'when send_invite is false' do
      let(:send_invite) { false }

      it 'does not send invite' do
        service.execute(user_data:, send_invite:)

        expect(NotificationFactory::Mailer).not_to have_received(:notification)
      end
    end
  end
end
