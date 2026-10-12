# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Auth::Backend::Base do

  let(:user)     { create(:user) }
  let(:password) { 'secure' }
  let(:auth)     { Auth.new(user.login, password) }
  let(:instance) { backend_class.new({ adapter: described_class.name }, auth) }

  let(:perform)           { true }
  let(:authenticated)     { true }
  let(:password_required) { true }
  let(:backend_class) do
    perform           = self.perform
    authenticated     = self.authenticated
    password_required = self.password_required

    Class.new(described_class) do
      define_method(:perform?)           { perform }
      define_method(:authenticated?)     { authenticated }
      define_method(:password_required?) { password_required }
      private :perform?, :authenticated?, :password_required?
    end
  end

  describe '#valid?' do
    it 'authenticates if the backend performs and authenticates' do
      expect(instance.valid?).to be true
    end

    context 'when the backend does not authenticate' do
      let(:authenticated) { false }

      it "doesn't authenticate" do
        expect(instance.valid?).to be false
      end
    end

    context 'when the backend does not perform' do
      let(:perform) { false }

      it "doesn't authenticate" do
        expect(instance.valid?).to be false
      end
    end

    context 'when the password is blank' do
      let(:password) { '' }

      it "doesn't authenticate" do
        expect(instance.valid?).to be false
      end

      context 'when the backend does not require a password' do
        let(:password_required) { false }

        it 'authenticates' do
          expect(instance.valid?).to be true
        end
      end
    end

    context 'when the backend does not implement perform? and authenticated?' do
      let(:instance) { described_class.new({ adapter: described_class.name }, auth) }

      it 'raises an error' do
        expect { instance.valid? }.to raise_error(NotImplementedError)
      end
    end
  end
end
