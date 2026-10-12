# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Auth::Backend::Internal do

  let(:user)     { create(:user) }
  let(:password) { 'secure' }
  let(:auth)     { Auth.new(user.login, password) }
  let(:instance) { described_class.new({ adapter: described_class.name }, auth) }

  describe '#valid?' do
    context 'when password is given' do
      let(:user) { create(:user, password: password) }

      it 'authenticates' do
        expect(instance.valid?).to be true
      end
    end

    context 'when very long password is given' do
      let(:password) { Faker::Lorem.characters(number: 1_111) }
      let(:user)     do
        # temporary override constant to create a test user with a very long password
        initial = PasswordPolicy::MaxLength::MAX_LENGTH
        stub_const 'PasswordPolicy::MaxLength::MAX_LENGTH', 99_999
        user = create(:user, password: password)
        stub_const 'PasswordPolicy::MaxLength::MAX_LENGTH', initial
        user
      end

      it 'does not try to verify it' do
        allow(PasswordHash).to receive(:verified?)

        instance.valid?

        expect(PasswordHash).not_to have_received(:verified?)
      end

      it 'returns false even though password is matching' do
        expect(instance).not_to be_valid
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

      it 'valid authentication' do
        expect(instance.valid?).to be true
      end

      it 'is password hash not legacy after validation' do
        instance.valid?
        expect(PasswordHash.legacy?(user.reload.password, password)).to be false
      end

      it 'is password hash argon2 after validation' do
        instance.valid?
        expect(PasswordHash).to be_hashed_argon2(user.reload.password)
      end
    end

    context 'when affecting Auth#increase_login_failed_attempts' do

      context 'when authentication fails' do
        let(:password) { 'wrong' }
        let(:user)     { create(:user, password: 'secure') }

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
