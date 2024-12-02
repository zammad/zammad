# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Report::Profile < ApplicationModel
  self.table_name = 'report_profiles'
  include ChecksConditionValidation
  include HasSearchIndexBackend
  include CanSelector
  include CanSearch

  validates :name, presence: true
  store     :condition

  def self.list
    where(active: true)
  end

end
