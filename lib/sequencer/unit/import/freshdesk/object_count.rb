# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Freshdesk::ObjectCount < Sequencer::Unit::Common::Provider::Attribute
  include ::Sequencer::Unit::Import::Common::Model::Statistics::Mixin::EmptyDiff
  prepend ::Sequencer::Unit::Import::Common::Model::Mixin::Skip::Action

  skip_action :skipped, :failed

  uses :model_class, :resources

  private

  def statistics_diff
    {
      model_key => empty_diff.merge!(
        total: resources.count
      )
    }
  end

  def model_key
    model_class.name.pluralize.to_sym
  end
end
