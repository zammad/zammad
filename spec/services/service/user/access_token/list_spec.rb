# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::User::AccessToken::List do
  let(:user) { create(:user) }

  let(:token)                { create(:token, user: user) }
  let(:token_second)         { create(:token, user: user) }
  let(:token_non_persistent) { create(:token, user: user, persistent: false) }
  let(:token_non_api)        { create(:token, user: user, action: :nonapi) }
  let(:token_another_user)   { create(:token) }

  before do
    token
    token_second
    token_non_persistent
    token_non_api
    token_another_user
  end

  it 'returns persistent api tokens owned by given user' do
    result = described_class.new(user).execute

    expect(result).to contain_exactly(token, token_second)
  end

  it 'does not include sensitive columns' do
    result = described_class.new(user).execute

    expect(result.first).not_to respond_to(:token)
  end
end
