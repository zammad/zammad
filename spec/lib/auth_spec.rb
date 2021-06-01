# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Auth do

  describe '.can_login?' do
    it 'responds to can_login?' do
      expect(described_class).to respond_to(:can_login?)
    end

    it 'checks if users can login' do
      user   = create(:user)
      result = described_class.can_login?(user)
      expect(result).to be true
    end

    context 'not loginable' do

      it 'fails if user has too many failed logins' do
        user   = create(:user, login_failed: 999)
        result = described_class.can_login?(user)
        expect(result).to be false
      end

      it "fails if user isn't active" do
        user   = create(:user, active: false)
        result = described_class.can_login?(user)
        expect(result).to be false
      end

      it 'fails if parameter is no User instance' do
        result = described_class.can_login?('user')
        expect(result).to be false
      end
    end

    context 'given default password_max_login_failed' do
      it 'passes with 5 attempts' do
        user   = create(:user, login_failed: 5)
        result = described_class.can_login?(user)
        expect(result).to be true
      end

      it 'fails with 6 attempts' do
        user   = create(:user, login_failed: 6)
        result = described_class.can_login?(user)
        expect(result).to be false
      end
    end
  end

  describe '.valid?' do
    it 'responds to valid?' do
      expect(described_class).to respond_to(:valid?)
    end

    it 'authenticates users' do
      password = 'zammad'
      user     = create(:user, password: password)
      result   = described_class.valid?(user, password)
      expect(result).to be true
    end
  end

  describe '.backends' do
    it 'responds to backends' do
      expect(described_class).to respond_to(:backends)
    end

    it 'returns a list of Hashes' do
      result = described_class.backends
      expect(result).to be_an(Array)
      expect(result.first).to be_a(Hash)
    end
  end
end
