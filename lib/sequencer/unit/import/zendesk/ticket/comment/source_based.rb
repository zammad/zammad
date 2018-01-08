class Sequencer
  class Unit
    module Import
      module Zendesk
        module Ticket
          module Comment
            class SourceBased < Sequencer::Unit::Common::Provider::Named

              uses :resource

              def value
                method_name = resource.via.channel.to_sym
                return if !respond_to?(method_name, true)
                send(method_name)
              end
            end
          end
        end
      end
    end
  end
end
