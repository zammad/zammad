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

  describe '#info', :aggregate_failures do
    let(:photo_url) { 'https://graph.microsoft.com/v1.0/me/photo/$value' }

    def photo_error(status:, parsed:, body: '')
      OAuth2::Error.new(instance_double(OAuth2::Response, status:, parsed:, body:))
    end

    it 'exposes the profile photo as image, fetched with a short timeout' do
      photo   = instance_double(OAuth2::Response, content_type: 'image/jpeg', body: 'jpeg-data')
      request = instance_double(Faraday::Request, options: Faraday::RequestOptions.new)
      allow(access_token).to receive(:get).with(photo_url).and_yield(request).and_return(photo)

      image = strategy.info[:image]

      expect(image.path).to end_with('.jpeg')
      expect(image.read).to eq('jpeg-data')
      expect(request.options.timeout).to eq(described_class::PROFILE_PHOTO_TIMEOUT)
    end

    it 'exposes no image when the user has no profile photo' do
      allow(access_token).to receive(:get).with(photo_url).and_raise(photo_error(status: 404, parsed: { 'error' => { 'code' => 'ImageNotFound' } }))

      expect(strategy.info).to include(email: 'john.doe@example.com', image: nil)
    end

    it 'exposes no image when Graph fails to deliver the profile photo' do
      allow(access_token).to receive(:get).with(photo_url).and_raise(photo_error(status: 500, parsed: { 'error' => { 'code' => 'UnknownError', 'message' => '' } }))

      expect(strategy.info).to include(email: 'john.doe@example.com', image: nil)
    end

    it 'exposes no image when the photo error carries no JSON body' do
      allow(access_token).to receive(:get).with(photo_url).and_raise(photo_error(status: 503, parsed: nil, body: '<html>Service Unavailable</html>'))

      expect(strategy.info).to include(email: 'john.doe@example.com', image: nil)
    end

    it 'exposes no image when the profile photo request times out' do
      allow(access_token).to receive(:get).with(photo_url).and_raise(OAuth2::TimeoutError, 'execution expired')

      expect(strategy.info).to include(email: 'john.doe@example.com', image: nil)
    end

    it 'exposes no image when the connection for the profile photo fails' do
      allow(access_token).to receive(:get).with(photo_url).and_raise(OAuth2::ConnectionError, 'Connection reset by peer')

      expect(strategy.info).to include(email: 'john.doe@example.com', image: nil)
    end
  end
end
