# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe OmniAuth::Strategies::MicrosoftOffice365Database do
  subject(:strategy) { described_class.allocate }

  let(:access_token)     { instance_double(OAuth2::AccessToken) }
  let(:profile)          { { 'mail' => 'john.doe@example.com' } }
  let(:profile_response) { instance_double(OAuth2::Response, parsed: profile) }

  before do
    strategy.access_token = access_token
    allow(access_token).to receive(:get).with('https://graph.microsoft.com/v1.0/me').and_return(profile_response)
  end

  describe '#extra', :aggregate_failures do
    it 'exposes the decoded ID token claims (e.g. "xms_edov") alongside the Graph /me profile' do
      id_token = JWT.encode({ 'xms_edov' => true }, nil, 'none')
      allow(access_token).to receive(:params).and_return({ 'id_token' => id_token })

      extra = strategy.extra

      expect(extra['raw_info']).to eq(profile)
      expect(extra['id_token_claims']['xms_edov']).to be(true)
    end

    it 'exposes no id_token_claims when no ID token is present' do
      allow(access_token).to receive(:params).and_return({})

      expect(strategy.extra).to eq('raw_info' => profile)
    end

    it 'exposes no id_token_claims when the ID token cannot be decoded' do
      allow(access_token).to receive(:params).and_return({ 'id_token' => 'not-a-jwt' })

      expect(strategy.extra).to eq('raw_info' => profile)
    end
  end
end
