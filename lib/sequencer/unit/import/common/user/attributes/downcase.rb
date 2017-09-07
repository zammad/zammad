class Sequencer
  class Unit
    module Import
      module Common
        module User
          module Attributes
            class Downcase < Sequencer::Unit::Base
              prepend ::Sequencer::Unit::Import::Common::Model::Mixin::SkipOnSkippedInstance

              uses :mapped

              def process
                %i(login email).each do |attribute|
                  next if mapped[attribute].blank?
                  mapped[attribute].downcase!
                end
              end
            end
          end
        end
      end
    end
  end
end
