module Mixin
  module HasBackends
    extend ActiveSupport::Concern

    included do
      cattr_accessor :backends do
        Set.new
      end

      require_dependency "#{name}::Backend".underscore
    end
  end
end
