# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Kayako
        module Case
          class Posts < Sequencer::Unit::Import::Kayako::SubSequence::SubObject
            prepend ::Sequencer::Unit::Import::Common::Model::Mixin::Skip::Action

            optional :action

            skip_action :skipped, :failed

            uses :resource

            def object
              'Post'
            end

            def sequence_name
              'Sequencer::Sequence::Import::Kayako::Posts'.freeze
            end

            def request_params
              super.merge(
                ticket: resource,
              )
            end
          end
        end
      end
    end
  end
end
