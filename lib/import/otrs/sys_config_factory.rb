# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Import
  module OTRS
    module SysConfigFactory
      extend self

      def import(settings, *_args)
        settings.each do |setting|
          next if direct_copy?(setting)
          next if number_generator?(setting)
          next if postmaster_default?(setting)
        end
      end

      def postmaster_default_lookup(key)
        @postmaster_defaults ||= {}
        @postmaster_defaults[key]
      end

      private

      def direct_settings
        %w[HttpType SystemID Organization TicketHook]
      end

      def direct_copy?(setting)
        cleaned_name = cleanup_name(setting['Key'])
        return false if direct_settings.exclude?(cleaned_name)

        internal_name = cleaned_name.underscore
        Setting.set(internal_name, setting['Value'])

        true
      end

      def cleanup_name(key)
        key.tr('::', '')
      end

      def number_generator?(setting)
        return false if setting['Key'] != 'Ticket::NumberGenerator'

        case setting['Value']
        when 'Kernel::System::Ticket::Number::DateChecksum'
          Setting.set('ticket_number', 'Ticket::Number::Date')
          Setting.set('ticket_number_date', { checksum: true })
        when 'Kernel::System::Ticket::Number::Date'
          Setting.set('ticket_number', 'Ticket::Number::Date')
          Setting.set('ticket_number_date', { checksum: false })
        end

        true
      end

      def postmaster_default?(setting)

        relevant_configs = %w[PostmasterDefaultPriority PostmasterDefaultState PostmasterFollowUpState]
        return false if relevant_configs.exclude?(setting['Key'])

        map = {
          'PostmasterDefaultPriority' => :priority_default_create,
          'PostmasterDefaultState'    => :state_default_create,
          'PostmasterFollowUpState'   => :state_default_follow_up,
        }

        @postmaster_defaults ||= {}
        @postmaster_defaults[ map[setting['Key']] ] = setting['Value']
        true
      end
    end
  end
end
