# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Report::Profile < ApplicationModel
  self.table_name = 'report_profiles'
  validates :name, presence: true
  store     :condition

  def self.list
    where(active: true)
  end

end
