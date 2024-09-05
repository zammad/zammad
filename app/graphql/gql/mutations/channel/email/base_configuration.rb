# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Channel::Email::BaseConfiguration < BaseMutation
    description 'Base class for configuration mutations'

    def self.authorize(_obj, ctx)
      ctx.current_user.permissions?('admin.channel_email')
    end

    protected

    def map_type_to_config(type)
      {
        adapter: type.adapter,
        options: type.to_h.except(:adapter)
      }
    end

    def map_probe_result(probe_result, field_prefix:)
      if probe_result[:result] == 'ok'
        return { success: true }.tap do |result|
          result[:mailbox_stats] = probe_result.slice(:content_messages, :archive_possible, :archive_possible_is_fallback, :archive_week_range) if probe_result[:content_messages]
        end
      end

      { success: false, errors: map_probe_errors_to_user_errors(probe_result, field_prefix:) }
    end

    def map_probe_errors_to_user_errors(probe_result, field_prefix:)
      error_message = probe_result[:message_human] || probe_result[:message]

      # generic error without triggering fields
      return [ { message: error_message } ] if probe_result[:invalid_field].blank?

      # field specific error(s)
      probe_result[:invalid_field].map do |key, _v|
        { message: error_message, field: [field_prefix, key].join('.') }
      end
    end
  end
end
