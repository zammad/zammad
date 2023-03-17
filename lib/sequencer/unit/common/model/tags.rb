# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Common::Model::Tags < Sequencer::Unit::Base
  prepend ::Sequencer::Unit::Import::Common::Model::Mixin::Skip::Action

  skip_action :skipped, :failed

  uses :dry_run, :instance

  def process
    return if dry_run
    return if tags.blank?

    Array(tags).each do |tag|
      instance.tag_add(tag, 1)
    end
  end

  private

  def tags
    raise NotImplementedError
  end
end
