# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::User::RemoveLinkedAccount do
  subject(:service) { described_class.new(provider:, uid:, current_user: user) }

  let(:user)          { create(:agent) }
  let(:authorization) { create(:twitter_authorization, user: user) }
  let(:provider)      { authorization.provider }
  let(:uid)           { authorization.uid }

  context 'with a valid authorization' do
    it 'removes the linked account' do
      service.execute
      expect { authorization.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context 'without a valid authorization' do
    let(:uid) { 'invalid-uid' }

    it 'raises an error' do
      expect { service.execute }.to raise_error(Exceptions::UnprocessableEntity)
    end
  end

end
