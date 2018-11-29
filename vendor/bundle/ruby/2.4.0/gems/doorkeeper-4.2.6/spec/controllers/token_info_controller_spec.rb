require 'spec_helper_integration'

describe Doorkeeper::TokenInfoController do
  describe 'when requesting tokeninfo with valid token' do
    let(:doorkeeper_token) { FactoryGirl.create(:access_token) }

    before(:each) do
      allow(controller).to receive(:doorkeeper_token) { doorkeeper_token }
    end

    def do_get
      get :show
    end

    describe 'successful request' do

      it 'responds with tokeninfo' do
        do_get
        expect(response.body).to eq(doorkeeper_token.to_json)
      end

      it 'responds with a 200 status' do
        do_get
        expect(response.status).to eq 200
      end
    end

    describe 'invalid token response' do
      before(:each) do
        allow(controller).to receive(:doorkeeper_token).and_return(nil)
      end
      it 'responds with 401 when doorkeeper_token is not valid' do
        do_get
        expect(response.status).to eq 401
        expect(response.headers['WWW-Authenticate']).to match(/^Bearer/)
      end

      it 'responds with 401 when doorkeeper_token is invalid, expired or revoked' do
        allow(controller).to receive(:doorkeeper_token).and_return(doorkeeper_token)
        allow(doorkeeper_token).to receive(:accessible?).and_return(false)
        do_get
        expect(response.status).to eq 401
        expect(response.headers['WWW-Authenticate']).to match(/^Bearer/)
      end

      it 'responds body message for error' do
        do_get
        expect(response.body).to eq(Doorkeeper::OAuth::ErrorResponse.new(name: :invalid_request, status: :unauthorized).body.to_json)
      end
    end
  end
end
