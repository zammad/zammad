# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

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
                    preferences:   store_preferences,
                    created_by_id: 1
                  )
                rescue => e
                  handle_failure(e)
                end

                private

                def store_preferences
                  output = { 'Content-Type' => resource.content_type }

                  if Store.resizable_mime? resource.content_type
                    output[:resizable]       = true
                    output[:content_preview] = true
                  end

                  output
                end
              end
            end
          end
        end
      end
    end
  end
end
