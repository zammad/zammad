# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Kayako
        module Post
          class InlineImages < Sequencer::Unit::Import::Common::Ticket::Article::InlineImages
            private

            def inline_image_url_prefix
              'kayako.com/media/url'
            end
          end
        end
      end
    end
  end
end
