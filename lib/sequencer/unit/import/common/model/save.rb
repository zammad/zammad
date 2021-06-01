# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require_dependency 'sequencer/unit/import/common/model/mixin/handle_failure'

class Sequencer
  class Unit
    module Import
      module Common
        module Model
          class Save < Sequencer::Unit::Base
            prepend ::Sequencer::Unit::Import::Common::Model::Mixin::Skip::Action
            include ::Sequencer::Unit::Import::Common::Model::Mixin::HandleFailure

            uses :instance, :action, :dry_run
            provides :instance

            skip_action :skipped, :failed, :unchanged

            def process
              return if dry_run
              return if instance.blank?

              save!
            end

            def save!
              BulkImportInfo.enable
              instance.save!
            rescue => e
              handle_failure(e)

              # unset instance if something went wrong
              state.provide(:instance, nil)
            ensure
              BulkImportInfo.disable
            end
          end
        end
      end
    end
  end
end
