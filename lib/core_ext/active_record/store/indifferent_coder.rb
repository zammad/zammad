# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

# Rails 5.0 has changed to only store and read ActiveSupport::HashWithIndifferentAccess from stores
# we extended lib/core_ext/active_record/store/indifferent_coder.rb to read also ActionController::Parameters
# and convert them to ActiveSupport::HashWithIndifferentAccess for migration in db/migrate/20171023000001_fixed_store_upgrade_ror_45.rb.
require 'active_record/store'
module ActiveRecord
  module Store
    class IndifferentCoder
      def self.as_indifferent_hash(obj)
        case obj
        # re-enable using ActionController::Parameters in stores
        when ActionController::Parameters
          obj.permit!.to_h
        # /re-enable using ActionController::Parameters in stores
        when ActiveSupport::HashWithIndifferentAccess
          obj
        when Hash
          obj.with_indifferent_access
        else
          ActiveSupport::HashWithIndifferentAccess.new
        end
      end
    end
  end
end
