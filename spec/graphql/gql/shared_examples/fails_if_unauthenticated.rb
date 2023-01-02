# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'graphql responds with error if unauthenticated' do
  context 'without authenticated session', authenticated_as: false do
    it 'fails with error message' do
      expect(gql.result.error_message).to eq('Authentication required')
    end

    it 'fails with error type' do
      expect(gql.result.error_type).to eq(Exceptions::NotAuthorized)
    end
  end
end
