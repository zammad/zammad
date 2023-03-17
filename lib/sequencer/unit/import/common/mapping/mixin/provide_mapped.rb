# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Sequencer::Unit::Import::Common::Mapping::Mixin::ProvideMapped

  def self.included(base)
    base.optional :mapped
    base.provides :mapped
  end

  private

  def existing_mapped
    @existing_mapped ||= begin
      # we need to use `state.optional` instead of just `mapped` here
      # to prevent naming conflicts with other Unit methods named `mapped`
      state.optional(:mapped) || ActiveSupport::HashWithIndifferentAccess.new
    end
  end

  def provide_mapped
    state.provide(:mapped) do
      existing_mapped.merge(yield)
    end
  end
end
