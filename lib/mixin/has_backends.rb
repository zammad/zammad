# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Mixin
  module HasBackends
    extend ActiveSupport::Concern

    included do
      class_attribute :backends do
        Set.new
      end

      self_path     = ActiveSupport::Dependencies.search_for_file name.underscore
      backends_path = self_path.delete_suffix File.extname(self_path)

      Mixin::RequiredSubPaths.eager_load_recursive backends_path

      backends = "#{name}::Backend".constantize.descendants

      self.backends = Set.new(backends)
    end
  end
end
