# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Kayako
        module Post
          module Channel
            class Helpcenter < Sequencer::Unit::Import::Kayako::Post::Channel::Mail
              private

              def article_type_name
                'web'
              end
            end
          end
        end
      end
    end
  end
end
