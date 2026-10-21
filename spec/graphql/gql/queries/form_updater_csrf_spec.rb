# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# The CSRF verification needs the controller, so use type: request.
RSpec.describe Gql::Queries::FormUpdater, allow_forgery_protection: true, type: :request do
  let(:password) { 'some_test_password' }
  let(:agent)    { create(:agent, password:) }
  let(:query) do
    <<~QUERY
      query formUpdater($formUpdaterId: EnumFormUpdaterId!, $relationFields: [FormUpdaterRelationField!]!, $meta: FormUpdaterMetaInput!, $data: JSON!) {
        formUpdater(formUpdaterId: $formUpdaterId, relationFields: $relationFields, meta: $meta, data: $data) {
          fields
        }
      }
    QUERY
  end
  let(:variables) { { formUpdaterId: 'FormUpdater__Updater__Ticket__Create', relationFields: [], meta: { formId: SecureRandom.uuid }, data: {} } }

  before do
    post '/api/v1/signshow', params: {}, as: :json
    post '/api/v1/signin', params: { username: agent.login, password:, fingerprint: '123456789' }, headers: { 'X-CSRF-Token' => response.headers['CSRF-TOKEN'] }
  end

  it 'answers a request with the CSRF token' do
    post '/graphql', params: { query:, variables: }, headers: { 'X-CSRF-Token' => response.headers['CSRF-TOKEN'] }, as: :json

    expect(json_response['data']['formUpdater']['fields']).to be_present
  end

  it 'refuses a request without the CSRF token' do
    post '/graphql', params: { query:, variables: }, as: :json

    expect(json_response['errors'][0]['extensions']).to include('type' => 'Exceptions::InvalidCSRFToken')
  end
end
