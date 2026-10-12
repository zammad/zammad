# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'graphql responds with forbidden' do
  it 'fails with forbidden error' do
    expect(gql.result.error_type).to eq(Exceptions::Forbidden)
  end
end
