# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Sequence
    module Import
      module Exchange
        class AttributesExamples < Sequencer::Sequence::Base

          def self.expecting
            [:attributes]
          end

          def self.sequence
            [
              'Exchange::Connection',
              'Exchange::Folders::ByIds',
              'Import::Exchange::AttributeExamples',
              'Import::Exchange::AttributeMapper::AttributeExamples',
            ]
          end
        end
      end
    end
  end
end
