# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Auth::User do

  let(:user)     { create(:user) }
  let(:instance) { described_class.new(user.login) }

  describe '.can_login?' do
    it 'responds to can_login?' do
      expect(instance).to respond_to(:can_login?)
    end

    shared_examples 'check loginable' do
      it 'checks if users can login' do
        expect(instance.can_login?).to be true
      end
    end

    shared_examples 'check not loginable' do
      it 'check that user can not login' do
        expect(instance.can_login?).to be false
      end
    end

    context 'with valid user login' do
      include_examples 'check loginable'
    end

    context 'with to many failed logins' do
      let(:user) { create(:user, login_failed: 999) }

      include_examples 'check not loginable'
    end

    context 'with not active user' do
      let(:user) { create(:user, active: false) }

      include_examples 'check not loginable'
    end

    context 'with invalid instance username parameter' do
      let(:instance) { described_class.new('not_existing') }

      include_examples 'check not loginable'
    end

    context 'with empty instance username parameter' do
      let(:instance) { described_class.new('') }

      include_examples 'check not loginable'
    end

    context 'with given default password_max_login_failed' do
      context 'with 5 attempts' do
        let(:user) { create(:user, login_failed: 5) }

        include_examples 'check loginable'
      end

      context 'with 6 attempts' do
        let(:user) { create(:user, login_failed: 6) }

        include_examples 'check not loginable'
      end
    end

    context 'when "password_max_login_failed" Setting is changed' do

      context 'when changed to lower value' do
        before do
          Setting.set('password_max_login_failed', 5)
          user.update(login_failed: 6)
        end

        include_examples 'check not loginable'
      end

      context 'when changed to nil' do
        before do
          Setting.set('password_max_login_failed', nil)
        end

        include_examples 'check loginable'

        context 'when User login failed once' do
          before do
            user.update(login_failed: 1)
          end

          include_examples 'check not loginable'
        end
      end
    end
  end
end
