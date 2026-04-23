# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::User::RemoveLinkedAccount do
  subject(:service_result) { described_class.with_current_user(user).execute(provider:, uid:) }

  let(:user)          { create(:agent) }
  let(:authorization) { create(:twitter_authorization, user: user) }
  let(:provider)      { authorization.provider }
  let(:uid)           { authorization.uid }

  context 'with a valid authorization' do
    it 'removes the linked account' do
      service_result
      expect { authorization.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context 'without a valid authorization' do
    let(:uid) { 'invalid-uid' }

    it 'raises an error' do
      expect { service_result }.to raise_error(Exceptions::UnprocessableContent)
    end
  end

end
