# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'
require 'lib/auth/backend_examples'

RSpec.describe Auth::Internal do

  let(:password) { 'zammad' }
  let(:user) { create(:user, password: password) }
  let(:instance) { described_class.new({ adapter: described_class.name }) }

  describe '#valid?' do
    it_behaves_like 'Auth backend'

    it 'authenticates via password' do
      result = instance.valid?(user, password)
      expect(result).to be true
    end

    it "doesn't authenticate via plain password" do
      result = instance.valid?(user, user.password)
      expect(result).to be_falsy
    end

    it 'converts legacy sha2 passwords' do

      sha2 = PasswordHash.sha2(password)
      user = create(:user, password: sha2)

      expect(PasswordHash.crypted?(user.password)).to be true
      expect(PasswordHash.legacy?(user.password, password)).to be true

      result = instance.valid?(user, password)
      expect(result).to be true

      expect(PasswordHash.legacy?(user.password, password)).to be false
      expect(PasswordHash.crypted?(user.password)).to be true
    end
  end
end
