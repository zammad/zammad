# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Report::Profile < ApplicationModel
  self.table_name = 'report_profiles'
  include ChecksConditionValidation
  validates :name, presence: true
  store     :condition

  def self.list
    where(active: true)
  end

end
