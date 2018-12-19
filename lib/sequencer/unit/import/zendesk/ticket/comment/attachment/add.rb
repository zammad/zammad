class Sequencer
  class Unit
    module Import
      module Zendesk
        module Ticket
          module Comment
            module Attachment
              class Add < Sequencer::Unit::Base
                prepend ::Sequencer::Unit::Import::Common::Model::Mixin::Skip::Action
                include ::Sequencer::Unit::Import::Common::Model::Mixin::HandleFailure

                skip_action :skipped

                uses :instance, :resource, :response, :model_class

                def process
                  ::Store.add(
                    object:        model_class.name,
                    o_id:          instance.id,
                    data:          response.body,
                    filename:      resource.file_name,
                    preferences:   {
                      'Content-Type' => resource.content_type
                    },
                    created_by_id: 1
                  )
                rescue => e
                  handle_failure(e)
                end
              end
            end
          end
        end
      end
    end
  end
end
