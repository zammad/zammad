# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'CORS Preflight Check', type: :request do

  shared_examples 'empty response' do
    it { expect(response).to have_http_status(:ok) }
    it { expect(response.body).to be_empty }
  end

  context 'valid route' do
    before do
      process :options, '/'
    end

    include_examples 'empty response'
  end

  context 'invalid route' do
    before do
      process :options, '/this_is_an_invalid_route'
    end

    include_examples 'empty response'
  end
end
