module Import
  module OTRS
    module Diff
      # rubocop:disable Style/ModuleFunction
      extend self

      def diff_worker
        return if !diff_import_possible?
        diff
      end

      private

      def diff_import_possible?
        return if !Setting.get('import_mode')
        return if Setting.get('import_otrs_endpoint') == 'http://otrs_host/otrs'
        true
      end

      def diff
        log 'Start diff...'

        check_import_mode

        updateable_objects

        # get changed tickets
        ticket_diff
      end

      def ticket_diff
        import_regular('Ticket', diff: true)
      end
    end
  end
end
