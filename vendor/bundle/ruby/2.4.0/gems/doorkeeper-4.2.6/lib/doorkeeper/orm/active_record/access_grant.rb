module Doorkeeper
  class AccessGrant < ActiveRecord::Base
    self.table_name = "#{table_name_prefix}oauth_access_grants#{table_name_suffix}".to_sym

    include AccessGrantMixin
  end
end
