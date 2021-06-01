# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Import
  module OTRS
    module Diff
      extend self

      def diff_worker
        return if !diff_import_possible?

        diff
      end

      def diff?
        return true if @diff

        false
      end

      private

      def diff_import_possible?
        return if !Setting.get('import_mode')
        return if Setting.get('import_otrs_endpoint') == 'http://otrs_host/otrs'

        true
      end

      def diff
        log 'Start diff...'

        @diff = true

        check_import_mode

        updateable_objects

        # get changed tickets
        ticket_diff
      end

      def ticket_diff
        import('Ticket', diff: true)
      end
    end
  end
end
