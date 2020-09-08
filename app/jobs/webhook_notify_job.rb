class WebhookNotifyJob < ApplicationJob

  def perform(webhook, activity)
   body = {
      id: activity.id,
      type: activity.type.name,
      object: {
        id: activity.o_id,
        type: activity.object.name.underscore
      },
      created_at: activity.created_at,
      updated_at: activity.updated_at
    }

    resp = Faraday.post(webhook.url, body.to_json,
      "Content-Type" => "application/json")

    # TODO: retry when error
  end
end
