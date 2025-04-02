# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'having token validity check' do |operation_name:|
  let(:operation) { send(operation_name) }

  context 'with an invalid token' do
    it 'raises an error', :aggregate_failures do
      allow(Token).to receive(:validate!).and_raise(Token::TokenAbsent)

      gql.execute(operation, variables: variables)

      expect(gql.result.error_type).to eq(Gql::Concerns::HandlesPasswordRevalidationToken::InvalidTokenError)
      expect(gql.result.error_message).to eq('The supplied password revalidation token is invalid.')
    end
  end
end

RSpec.shared_examples 'cleaning up used token' do |operation_name:|
  let(:operation) { send(operation_name) }

  it 'removes token' do
    gql.execute(operation, variables: variables)

    expect(Token).not_to exist(token:)
  end
end

RSpec.shared_examples 'keeping used token' do |operation_name:|
  let(:operation) { send(operation_name) }

  it 'keeps token' do
    gql.execute(operation, variables: variables)

    expect(Token).to exist(token:)
  end
end
