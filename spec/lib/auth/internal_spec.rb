require 'rails_helper'

RSpec.describe Auth::Internal do

  it 'authenticates via password' do
    user     = create(:user)
    password = 'zammad'
    result   = described_class.check(user.login, password, {}, user)

    expect(result).to be_an_instance_of(User)
  end

  it "doesn't authenticate via plain password" do
    user   = create(:user)
    result = described_class.check(user.login, user.password, {}, user)

    expect(result).to be_falsy
  end

  it 'converts legacy sha2 passwords' do
    user     = create(:user_legacy_password_sha2)
    password = 'zammad'

    expect(PasswordHash.crypted?(user.password)).to be_falsy

    result = described_class.check(user.login, password, {}, user)

    expect(result).to be_an_instance_of(User)
    expect(PasswordHash.crypted?(user.password)).to be true
  end
end
