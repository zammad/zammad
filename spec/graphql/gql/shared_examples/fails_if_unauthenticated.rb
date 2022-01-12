# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'graphql responds with error if unauthenticated' do
  context 'without authenticated session', authenticated_as: false do
    it 'fails with error message' do
      expect(graphql_response['errors'][0]).to include('message' => 'Authentication required')
    end

    it 'fails with error type' do
      expect(graphql_response['errors'][0]['extensions']).to include({ 'type' => 'Exceptions::NotAuthorized' })
    end
  end
end
