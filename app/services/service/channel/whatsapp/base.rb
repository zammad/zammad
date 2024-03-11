# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Service::Channel::Whatsapp
  class Base < Service::Base
    attr_reader :params

    private

    def area
      'WhatsApp::Business'.freeze
    end

    def area_channel_list
      Channel.in_area(area)
    end

    def attributes_hash
      {
        group_id:,
        options:
      }
    end

    def group_id
      params[:group_id]
    end

    def options
      params.slice(
        :business_id, :access_token, :app_secret, :phone_number_id, :welcome, :reminder_active
      )
    end

    def add_metadata(channel:, initial: false)
      phone_number_info = get_phone_number_info(channel)

      raise __('Could not fetch WhatsApp phone number details.') if phone_number_info.nil?

      channel.options.merge! phone_number_info
      channel.options.merge! initial_options if initial

      channel.save!
    end

    def get_phone_number_info(channel)
      Whatsapp::Account::PhoneNumbers
        .new(**channel.options.slice(:business_id, :access_token).symbolize_keys)
        .get(channel.options[:phone_number_id])
    end

    def initial_options
      {
        adapter:           'whatsapp',
        callback_url_uuid: SecureRandom.uuid,
        verify_token:      SecureRandom.urlsafe_base64(12),
      }
    end
  end
end
