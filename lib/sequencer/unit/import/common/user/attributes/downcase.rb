# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Common
        module User
          module Attributes
            class Downcase < Sequencer::Unit::Base
              prepend ::Sequencer::Unit::Import::Common::Model::Mixin::Skip::Action

              skip_action :skipped, :failed

              uses :mapped

              def process
                %i[login email].each do |attribute|
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
