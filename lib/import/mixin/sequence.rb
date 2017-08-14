module Import
  module Mixin
    module Sequence
      private

      def sequence_name
        raise "Missing implementation of '#{__method__}' method for '#{self.class.name}'"
      end

      def process
        Sequencer.process(sequence_name,
                          parameters: {
                            import_job: @import_job
                          })
      end
      alias start_import process
    end
  end
end
