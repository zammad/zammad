module Import
  module OTRS
    module SysConfigFactory

      # rubocop:disable Style/ModuleFunction
      extend self

      def import(settings)
        settings.each do |setting|
          next if direct_copy?(setting)
          next if number_generator?(setting)
        end
      end

      private

      def direct_settings
        %w(HttpType SystemID Organization TicketHook)
      end

      def direct_copy?(setting)
        cleaned_name = cleanup_name(setting['Key'])
        return false if !direct_settings.include?(cleaned_name)

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
    end
  end
end
