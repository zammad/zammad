# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Common::Model::Save < Sequencer::Unit::Base
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
