# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe GraphqlChannel, type: :channel do
  # https://github.com/zammad/zammad/issues/5401
  describe 'setting UserInfo.current_user_id thread variable' do
    class TestQuery < Gql::Queries::BaseQuery # rubocop:disable RSpec/LeakyConstantDeclaration, Lint/ConstantDefinitionInBlock
      type Gql::Types::UserType, null: true

      def resolve
        User.find_by id: UserInfo.current_user_id
      end
    end

    let(:query) do
      <<~QUERY
        query testQuery {
          testQuery {
            id
          }
        }
      QUERY
    end

    context 'when connected with a session with a user' do
      let(:user) { create(:agent) }

      it 'sets UserInfo.current_user_id for the operation' do
        stub_connection sid: '123_456', current_user: user

        subscribe

        perform :execute, operationName: 'testQuery', query: query

        expect(transmissions.last).to include(
          result: include(
            data: include(testQuery: include(id: user.to_global_id.to_s))
          )
        )
      end
    end

    context 'when connected with a userless session' do
      it 'sets UserInfo.current_user_id for the operation' do
        stub_connection sid: '123_456', current_user: nil

        subscribe

        perform :execute, operationName: 'testQuery', query: query

        expect(transmissions.last).to include(
          result: include(
            data: include(testQuery: be_nil)
          )
        )
      end
    end
  end
end
