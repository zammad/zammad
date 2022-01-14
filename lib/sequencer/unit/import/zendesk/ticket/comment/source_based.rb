# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Zendesk
        module Ticket
          module Comment
            class SourceBased < Sequencer::Unit::Common::Provider::Named

              uses :resource

              def value
                return if private_methods(false).exclude?(value_method_name)

                send(value_method_name)
              end

              def value_method_name
                @value_method_name ||= resource.via.channel.to_sym
              end
            end
          end
        end
      end
    end
  end
end
