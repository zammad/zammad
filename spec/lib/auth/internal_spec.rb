require 'rails_helper'
require 'lib/auth/backend_examples'

RSpec.describe Auth::Internal do

  let(:user) { create(:user) }
  let(:instance) { described_class.new({ adapter: described_class.name }) }

  context '#valid?' do
    it_behaves_like 'Auth backend'

    it 'authenticates via password' do
      result = instance.valid?(user, 'zammad')
      expect(result).to be true
    end

    it "doesn't authenticate via plain password" do
      result = instance.valid?(user, user.password)
      expect(result).to be_falsy
    end

    it 'converts legacy sha2 passwords' do

      pw_plain = 'zammad'
      sha2_pw  = PasswordHash.sha2(pw_plain)
      user     = create(:user, password: sha2_pw)

      expect(PasswordHash.crypted?(user.password)).to be true
      expect(PasswordHash.legacy?(user.password, pw_plain)).to be true

      result = instance.valid?(user, pw_plain)
      expect(result).to be true

      expect(PasswordHash.legacy?(user.password, pw_plain)).to be false
      expect(PasswordHash.crypted?(user.password)).to be true
    end
  end
end
