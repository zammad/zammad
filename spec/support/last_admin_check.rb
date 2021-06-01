# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

RSpec.configure do |config|

  config.around(:example, last_admin_check: false) do |example|

    User.class_eval do
      alias_method :original_last_admin_check_admin_count, :last_admin_check_admin_count

      def last_admin_check_admin_count
        1
      end
    end

    example.run

    User.class_eval do
      alias_method :last_admin_check_admin_count, :original_last_admin_check_admin_count
      remove_method :original_last_admin_check_admin_count
    end
  end
end
