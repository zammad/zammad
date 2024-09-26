# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Service::Channel::Whatsapp
  class Update < Base
    attr_reader :channel_id

    def initialize(params:, channel_id:)
      super()

      @channel_id = channel_id
      @params     = params
    end

    def options
      channel.options.merge(
        params.slice(
          :business_id, :access_token, :app_secret, :phone_number_id, :welcome, :reminder_active, :reminder_message
        )
      )
    end

    def execute
      ActiveRecord::Base.transaction do
        channel
          .tap { |channel| channel.update!(**attributes_hash) }
          .tap { |channel| add_metadata(channel:) }
      end
    end

    private

    def channel
      area_channel_list.find(channel_id)
    end
  end
end
