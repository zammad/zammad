# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'
require 'lib/auth/backend/backend_examples'

RSpec.describe Auth::Backend::Internal do

  let(:user) { create(:user) }
  let(:password) { 'secure' }
  let(:auth) { Auth.new(user.login, password) }
  let(:instance) { described_class.new({ adapter: described_class.name }, auth) }

  describe '#valid?' do
    it_behaves_like 'Auth backend'

    context 'when password is given' do
      let(:user) { create(:user, password: password) }

      it 'authenticates' do
        expect(instance.valid?).to be true
      end
    end

    context 'when given password matches stored hash' do

      let(:password) { user.password }
      let(:user) { create(:user, password: 'secure') }

      it "doesn't authenticate" do
        expect(instance.valid?).to be false
      end
    end

    context 'when given password is blank' do
      let(:password) { '' }
      let(:user) { create(:user, password: 'secure') }

      it "doesn't authenticate" do
        expect(instance.valid?).to be false
      end
    end

    context 'with legacy SHA2 passwords' do
      let(:user) { create(:user, password: PasswordHash.sha2(password)) }

      it 'is password hash crypted' do
        expect(PasswordHash.crypted?(user.password)).to be true
      end

      it 'is password hash legacy' do
        expect(PasswordHash.legacy?(user.password, password)).to be true
      end

      it 'valid authentication' do
        expect(instance.valid?).to be true
      end

      it 'is password hash not legacy after validation' do
        instance.valid?
        expect(PasswordHash.legacy?(user.reload.password, password)).to be false
      end

      it 'is password hash crypted after validation' do
        instance.valid?
        expect(PasswordHash.crypted?(user.password)).to be true
      end
    end

    context 'when affecting Auth#increase_login_failed_attempts' do

      context 'when authentication fails' do
        let(:password) { 'wrong' }
        let(:user) { create(:user, password: 'secure') }

        it 'sets Auth#increase_login_failed_attempts flag to true' do
          expect { instance.valid? }.to change(auth, :increase_login_failed_attempts).from(false).to(true)
        end
      end

      context 'when authentication succeeds' do
        let(:user) { create(:user, password: password) }

        it "doesn't change Auth#increase_login_failed_attempts flag" do
          expect { instance.valid? }.not_to change(auth, :increase_login_failed_attempts)
        end
      end
    end
  end
end
