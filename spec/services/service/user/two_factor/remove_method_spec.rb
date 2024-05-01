# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::User::TwoFactor::RemoveMethod do
  subject(:service) { described_class.new(user:, method_name:) }

  let(:user) { create(:agent) }

  context 'when the given method exists' do
    let(:method_name) { 'authenticator_app' }

    context 'when user has given method configured' do
      let(:preference) { create(:user_two_factor_preference, :authenticator_app, user:) }

      before { preference }

      it 'removes the given method' do
        expect { service.execute }
          .to change { preference.class.exists?(preference.id) }
          .to be_falsey
      end
    end

    context 'when user does not have given method configured' do
      it 'does not raise error' do
        expect { service.execute }.not_to raise_error
      end
    end
  end

  context 'when the given method does not exist' do
    let(:method_name) { 'nonsense' }

    it 'raises error' do
      expect { service.execute }.to raise_error(Exceptions::UnprocessableEntity)
    end
  end
end
