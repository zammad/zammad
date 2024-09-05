# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Channel::Email::GuessConfiguration < Channel::Email::BaseConfiguration
    description 'Try to guess email channel configuration from user credentials'

    argument :email_address, String, description: 'User email address to guess configuration for'
    argument :password, String, description: 'User password'

    field :result, Gql::Types::Channel::Email::GuessConfigurationResult, null: false, description: 'Holds the guessed configurations.'

    def resolve(email_address:, password:)
      internal_result = EmailHelper::Probe.full(email: email_address, password:)

      return { result: {} } if !internal_result || internal_result[:result] != 'ok'

      {
        result: {
          inbound_configuration:  map_config_to_type(internal_result.dig(:setting, :inbound)),
          outbound_configuration: map_config_to_type(internal_result.dig(:setting, :outbound)),
        }.tap do |result|
          result[:mailbox_stats] = internal_result.slice(:content_messages, :archive_possible, :archive_possible_is_fallback, :archive_week_range) if internal_result[:content_messages]
        end
      }
    end

    private

    def map_config_to_type(hash)
      return nil if !hash.is_a?(Hash)

      hash
        .slice(:adapter)
        .merge(hash[:options])
        .tap { _1[:ssl] = map_ssl_value(_1) }
    end

    def map_ssl_value(hash)
      if hash[:start_tls]
        'starttls'
      elsif hash[:ssl]
        'ssl'
      else
        'off'
      end
    end
  end
end
