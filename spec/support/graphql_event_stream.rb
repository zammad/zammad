# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module GraphqlEventStream
  # The server subscribes to the Redis event stream of a GraphQL subscription asynchronously
  #   (stream_from), after the client already got the initial answer.
  def self.subscribed?(name, entity: nil, scope: nil)
    # Scope to the channel prefix of the current environment
    channel_prefix = Rails.application.config.action_cable.cable[:channel_prefix]

    # A subscription scoped per user puts the user id in front of the name, e.g. "graphql-event:5:ctiSidebarUpdates:".
    #   Without the scope, the channel of another user could satisfy the wait.
    pattern = scope ? "#{channel_prefix}:graphql-event:#{scope.id}:#{name}:*" : "#{channel_prefix}:graphql-event:*#{name}*"
    pattern += "#{entity.to_global_id}*" if entity

    redis.pubsub('CHANNELS', pattern).any?
  end

  def self.redis
    @redis ||= Zammad::Service::Redis.new
  end
end
