class Sequencer
  class Unit
    module Import
      module Zendesk
        module Mixin
          module IncrementalExport

            def self.included(base)
              base.uses :client
            end

            def resource_collection
              "::ZendeskAPI::#{resource_klass}".constantize.incremental_export(client, 1)
            end
          end
        end
      end
    end
  end
end
