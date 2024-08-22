# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Authorization::Provider, :aggregate_failures, type: :model do
  context "with setting 'auth_third_party_no_create_user'" do
    let(:uid)   { SecureRandom.uuid }
    let(:auth_hash) do
      {
        'info' => { 'email' => Faker::Internet.email },
        'uid'  => uid,
      }
    end

    context 'when is enabled' do
      before do
        Setting.set('auth_third_party_no_create_user', true)
      end

      it 'does not create a new user, logs and raises an error' do
        allow(Rails.logger).to receive(:error)

        expect { described_class.new(auth_hash) }.to raise_error(Authorization::Provider::AccountError)

        message = "User account '#{uid}' not found for authentication provider 'Provider'."
        expect(Rails.logger).to have_received(:error).with(no_args).once do |&block|
          expect(block.call).to eq(message)
        end

        expect(User.find_by(email: auth_hash['info']['email'])).to be_nil
      end
    end

    context 'when is disabled' do
      before do
        Setting.set('auth_third_party_no_create_user', false)
      end

      it 'creates a new user' do
        expect { described_class.new(auth_hash) }.to change(User, :count).by(1)
      end
    end
  end
end
