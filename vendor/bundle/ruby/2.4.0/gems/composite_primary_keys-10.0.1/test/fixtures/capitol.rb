class Capitol < ActiveRecord::Base
  self.primary_keys = :country, :city
end
