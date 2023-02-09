# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'graphql/gql/shared_examples/fails_if_unauthenticated'

module ZammadSpecSupportGraphql
  #
  # A stub implementation of ActionCable.
  # Any methods to support the mock backend have `mock` in the name.
  # Taken from github.com/rmosolgo/graphql-ruby/blob/master/spec/graphql/subscriptions/action_cable_subscriptions_spec.rb
  #
  class MockActionCable
    class MockChannel
      def initialize
        @mock_broadcasted_messages = []
      end

      attr_reader :mock_broadcasted_messages

      def stream_from(stream_name, coder: nil, &block)
        # Rails uses `coder`, we don't
        block ||= ->(msg) { @mock_broadcasted_messages << msg }
        MockActionCable.mock_stream_for(stream_name).add_mock_channel(self, block)
      end

      def mock_broadcasted_at(index)
        data = mock_broadcasted_messages.dig(index, :result)

        return if !data

        GraphQLHelpers::Result.new(data)
      end

      def mock_broadcasted_first
        mock_broadcasted_at(0)
      end
    end

    class MockStream
      def initialize
        @mock_channels = {}
      end

      def add_mock_channel(channel, handler)
        @mock_channels[channel] = handler
      end

      def mock_broadcast(message)
        @mock_channels.each do |_channel, handler|
          handler&.call(message)
        end
      end
    end

    class << self
      def clear_mocks
        @mock_streams = {}
      end

      def server
        self
      end

      def broadcast(stream_name, message)
        stream = @mock_streams[stream_name]
        stream&.mock_broadcast(message)
      end

      def mock_stream_for(stream_name)
        @mock_streams[stream_name] ||= MockStream.new
      end

      def build_mock_channel
        MockChannel.new
      end

      def mock_stream_names
        @mock_streams.keys
      end
    end
  end

  #
  # Create a mock channel that can be passed to graphql_execute like this:
  #
  #   let(:mock_channel) { build_mock_channel }
  #
  #   gql.execute(query, context: { channel: mock_channel })
  #
  delegate :build_mock_channel, to: MockActionCable

  #
  # A set of GraphQL helpers. Access them in a :graphql test via `gql.*`.
  #
  class GraphQLHelpers

    #
    # Encapsulates the GraphQL result.
    #
    #   gql.result.*
    #
    class Result
      attr_reader :payload

      def initialize(payload)
        @payload = payload
      end

      #
      # Access the data payload. This asserts that only one operation was executed
      #   and that no errors are present.
      #
      #   expect(gql.response.data).to include(...)
      #
      def data
        assert('GraphQL result does not contain errors') do
          @payload['errors'].nil?
        end
        assert('GraphQL result contains exactly one data entry') do
          @payload['data']&.count == 1
        end
        @payload['data'].values.first
      end

      #
      # Access the edges->node data payload from `#data()` in a convenient way.
      #
      #   expect(gql.response.nodes.first).to include(...)
      #
      # Also can operate on a subentry in the hash rather than the top level.
      #
      #   expect(gql.response.nodes('first_level', 'second_level').first).to include(...)
      #
      def nodes(*subkeys)
        content = data.dig(*subkeys, 'edges')
        assert('GraphQL result contains node entries') do
          !content.nil?
        end
        content.pluck('node')
      end

      #
      # Access an error entry. This asserts that only one error and no data payload is present.
      #
      #   expect(gql.result.error).to include(...)
      #
      def error
        assert('GraphQL result does not contain data') do
          @payload['data'].nil? || @payload['data'].values.first.nil?
        end
        assert('GraphQL result contains exactly one error entry') do
          @payload['errors']&.count == 1
        end
        @payload['errors'][0]
      end

      #
      # Access the error type from `#error()` and return it as a Ruby class.
      #
      #   expect(gql.result.error_type).to eq(ActiveRecord::RecordNotFound)
      #
      def error_type
        assert('GraphQL result has error type') do
          error.dig('extensions', 'type').present?
        end
        error.dig('extensions', 'type').constantize
      end

      #
      # Access the error message from `#error()`.
      #
      #   expect(gql.result.error_message).to eq('Something went wrong in this test...')
      #
      def error_message
        error['message']
      end

      private

      def assert(message)
        raise "Assertion '#{message}' failed, graphql result:\n#{PP.pp(payload, '')}" if !yield # rubocop:disable Lint/Debugger
      end
    end

    attr_writer :graphql_current_user
    attr_accessor :result

    # Shortcut to generate a GraphQL ID for an object.
    def id(object)
      Gql::ZammadSchema.id_from_object(object)
    end

    #
    # Run a graphql query.
    #
    #   before do
    #     gql.execute(query, variables: { ... })
    #   end
    #
    # Afterwards, the `Result` can be accessed via
    #
    #   gql.result
    #
    def execute(query, variables: {}, context: {})
      context[:current_user] ||= @graphql_current_user
      if @graphql_current_user
        # TODO: we only fake a SID for now, create a real session?
        context[:sid] = SecureRandom.hex(16)

        # we need to set the current_user_id in the UserInfo context as well
        UserInfo.current_user_id = context[:current_user].id
      end
      @result = Result.new(Gql::ZammadSchema.execute(query, variables: variables, context: context).to_h)
    end
  end

  def gql
    @gql ||= GraphQLHelpers.new
  end
end

RSpec.configure do |config|
  config.include ZammadSpecSupportGraphql, type: :graphql

  config.prepend_before(:each, type: :graphql) do
    ZammadSpecSupportGraphql::MockActionCable.clear_mocks
    Gql::ZammadSchema.subscriptions = GraphQL::Subscriptions::ActionCableSubscriptions.new(
      action_cable: ZammadSpecSupportGraphql::MockActionCable, action_cable_coder: JSON, schema: Gql::ZammadSchema
    )
  end

  config.append_after(:each, type: :graphql) do
    Gql::ZammadSchema.subscriptions = GraphQL::Subscriptions::ActionCableSubscriptions.new(schema: Gql::ZammadSchema)
  end

  # This helper allows you to authenticate as a given user in :graphql specs
  # via the example metadata, rather than directly:
  #
  #     it 'does something', authenticated_as: :user
  #
  # In order for this to work, you must define the user in a `let` block first:
  #
  #     let(:user) { create(:customer) }
  #
  config.before(:each, :authenticated_as, type: :graphql) do |example|
    gql.graphql_current_user = authenticated_as_get_user example.metadata[:authenticated_as], return_type: :user
  end

  # Temporary Hack: skip tests if ENABLE_EXPERIMENTAL_MOBILE_FRONTEND is not set.
  # TODO: Remove when this switch is not needed any more.
  config.around(:each, type: :graphql) do |example|
    example.run if ENV['ENABLE_EXPERIMENTAL_MOBILE_FRONTEND'] == 'true'
  end
end
