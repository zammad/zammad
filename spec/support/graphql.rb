# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'graphql/gql/shared_examples/fails_if_unauthenticated'

module ZammadSpecSupportGraphql
  #
  # Taken from github.com/rmosolgo/graphql-ruby/blob/master/spec/graphql/subscriptions/action_cable_subscriptions_spec.rb
  #

  # A stub implementation of ActionCable.
  # Any methods to support the mock backend have `mock` in the name.
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

  def graphql_current_user=(user)
    @graphql_current_user = user
  end

  #
  # Run a graphql query.
  #
  def graphql_execute(query, variables: {}, context: {})
    context[:current_user] ||= @graphql_current_user
    if @graphql_current_user
      # TODO: we only fake a SID for now, create a real session?
      context[:sid] = SecureRandom.hex(16)
    end
    @graphql_result = Gql::ZammadSchema.execute(query, variables: variables, context: context)
  end

  #
  # Response of the previous graphql_execute call.
  #
  def graphql_response
    @graphql_result
  end

  #
  # Create a mock channel that can be passed to graphql_execute like this:
  #
  #   let(:mock_channel) { build_mock_channel }
  #
  #   graphql_execute(query, context: { channel: mock_channel })
  #
  delegate :build_mock_channel, to: MockActionCable

  #
  # Read a graphql query definition file from app/frontend/*.
  #
  def read_graphql_file(filename)
    File.read(Rails.root.join("app/frontend/#{filename}"))
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

  # This helper allows you to authenticate as a given user in request specs
  # via the example metadata, rather than directly:
  #
  #     it 'does something', authenticated_as: :user
  #
  # In order for this to work, you must define the user in a `let` block first:
  #
  #     let(:user) { create(:customer) }
  #
  config.before(:each, :authenticated_as, type: :graphql) do |example|
    self.graphql_current_user = authenticated_as_get_user example.metadata[:authenticated_as], return_type: :user
  end
end
