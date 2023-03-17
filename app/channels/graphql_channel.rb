# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class GraphqlChannel < ApplicationCable::Channel
  def subscribed
    @subscription_ids = []
  end

  def execute(data)
    query = data['query']
    variables = ensure_hash(data['variables'])
    operation_name = data['operationName']

    # context must be kept in sync with GraphqlController!
    context = {
      sid:          sid,
      current_user: current_user,
      # :channel is required for ActionCableSubscriptions and MUST NOT be used otherwise.
      channel:      self,
    }

    result = Gql::ZammadSchema.execute(query:, context:, variables:, operation_name:)

    payload = {
      result: result.to_h,
      more:   result.subscription?,
    }

    # Track the subscription here so we can remove it
    # on unsubscribe.
    if result.context[:subscription_id]
      @subscription_ids << result.context[:subscription_id]
    end

    transmit(payload)
  end

  def unsubscribed
    @subscription_ids.each do |sid|
      Gql::ZammadSchema.subscriptions.delete_subscription(sid)
    end
  end

  private

  def ensure_hash(ambiguous_param)
    case ambiguous_param
    when String
      if ambiguous_param.present?
        ensure_hash(JSON.parse(ambiguous_param))
      else
        {}
      end
    when Hash, ActionController::Parameters
      ambiguous_param
    when nil
      {}
    else
      raise ArgumentError, "Unexpected parameter: #{ambiguous_param}"
    end
  end
end
