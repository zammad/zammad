# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Import
  module Mixin
    module Sequence
      private

      def sequence_name
        raise "Missing implementation of '#{__method__}' method for '#{self.class.name}'"
      end

      def process
        # remove previous result information that may still be saved
        # in case an import job was rescheduled
        @import_job.update!(result: {})

        Sequencer.process(sequence_name,
                          parameters: {
                            import_job: @import_job
                          })
      end
      alias start_import process
    end
  end
end
