# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class ExternalCredential::Base::ChannelXoauth2
  def self.channel_area
    raise NotImplementedError
  end

  def self.update_client_secret(previous_client_secret, current_client_secret)
    Channel.in_area(channel_area).find_each do |channel|
      channel_client_secret = channel.options.dig(:auth, :client_secret)
      next if channel_client_secret.blank?
      next if channel_client_secret != previous_client_secret

      channel.options[:auth][:client_secret] = current_client_secret
      channel.save!
    end

    true
  end
end
