require 'rails_helper'

RSpec.describe User do

  let(:new_password) { 'N3W54V3PW!' }

  context 'password' do

    it 'resets login_failed on password change' do
      user = create(:user_login_failed)
      expect {
        user.password = new_password
        user.save
      }.to change { user.login_failed }.to(0)
    end
  end

  context '#by_reset_token' do

    it 'returns a User instance for existing tokens' do
      token = create(:token_password_reset)
      expect(described_class.by_reset_token(token.name)).to be_instance_of(described_class)
    end

    it 'returns nil for not existing tokens' do
      expect(described_class.by_reset_token('not-existing')).to be nil
    end
  end

  context '#password_reset_via_token' do

    it 'changes the password of the token user and destroys the token' do
      token = create(:token_password_reset)
      user  = User.find(token.user_id)

      expect {
        described_class.password_reset_via_token(token.name, new_password)
        user.reload
      }.to change {
        user.password
      }.and change {
        Token.count
      }.by(-1)
    end
  end

end
