# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Zendesk
        module User
          class ImageSource < Sequencer::Unit::Common::Provider::Named

            uses :resource

            private

            def image_source
              resource&.photo&.content_url
            end
          end
        end
      end
    end
  end
end
