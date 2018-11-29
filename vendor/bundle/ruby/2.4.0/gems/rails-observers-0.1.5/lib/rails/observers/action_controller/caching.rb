module ActionController #:nodoc:
  module Caching
    extend ActiveSupport::Autoload

    eager_autoload do
      autoload :Sweeper,  'rails/observers/action_controller/caching/sweeper'
      autoload :Sweeping, 'rails/observers/action_controller/caching/sweeping'
    end

    ActionController::Base.extend Sweeping::ClassMethods if defined?(ActiveRecord)
  end
end
