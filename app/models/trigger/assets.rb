# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Trigger
  module Assets
    extend ActiveSupport::Concern

=begin

get all assets / related models for this trigger

  trigger = Trigger.find(123)
  result = trigger.assets(assets_if_exists)

returns

  result = {
    :triggers => {
      123  => trigger_model_123,
      1234 => trigger_model_1234,
    }
  }

=end

    def assets(data)

      app_model_trigger = Trigger.to_app_model
      data[ app_model_trigger ] ||= {}

      return data if data[ app_model_trigger ][ id ]

      data[ app_model_trigger ][ id ] = attributes_with_association_ids
      data = assets_of_selector('condition', data)
      data = assets_of_selector('perform', data)

      app_model_calendar = Calendar.to_app_model
      data[ app_model_calendar ] ||= {}
      Calendar.find_each do |calendar|
        data = calendar.assets(data)
      end

      app_model_webhook = Webhook.to_app_model
      data[ app_model_webhook ] ||= {}
      Webhook.find_each do |webhook|
        data = webhook.assets(data)
      end

      app_model_user = User.to_app_model
      data[ app_model_user ] ||= {}

      %w[created_by_id updated_by_id].each do |local_user_id|
        next if !self[ local_user_id ]
        next if data[ app_model_user ][ self[ local_user_id ] ]

        user = User.lookup(id: self[ local_user_id ])
        next if !user

        data = user.assets(data)
      end
      data
    end
  end
end
