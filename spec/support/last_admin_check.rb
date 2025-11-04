# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

RSpec.configure do |config|
  config.around(:example, last_admin_check: false) do |example|
    User.singleton_class.class_eval do
      alias_method :orig_admin_user_exists?, :admin_user_exists?
      define_method(:admin_user_exists?) { |**_args| true }
    end

    example.run
  ensure
    User.singleton_class.class_eval do
      alias_method :admin_user_exists?, :orig_admin_user_exists?
      remove_method :orig_admin_user_exists?
    end
  end
end
