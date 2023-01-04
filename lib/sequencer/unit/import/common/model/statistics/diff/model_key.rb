# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Common::Model::Statistics::Diff::ModelKey < Sequencer::Unit::Base
  include ::Sequencer::Unit::Import::Common::Model::Statistics::Mixin::ActionDiff

  uses :model_class

  def process
    state.provide(:statistics_diff) do
      {
        model_key => diff,
      }
    end
  end

  private

  def model_key
    model_class.name.pluralize.to_sym
  end
end
