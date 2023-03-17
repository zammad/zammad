# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Mixin
  module HasBackends
    extend ActiveSupport::Concern

    included do
      class_attribute :backends do
        Set.new
      end

      self_path     = ActiveSupport::Dependencies.search_for_file name.underscore
      backends_path = self_path.delete_suffix File.extname(self_path)

      Mixin::RequiredSubPaths.eager_load_recursive name, backends_path

      backends = "#{name}::Backend".constantize.descendants

      self.backends = Set.new(backends)
    end
  end
end
