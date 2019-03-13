module Mixin
  module IsBackend
    extend ActiveSupport::Concern

    class_methods do

      def is_backend_of(klass) # rubocop:disable Naming/PredicateName
        klass.backends.add(self)
      end
    end
  end
end
