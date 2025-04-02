# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Report::Profile < ApplicationModel
  self.table_name = 'report_profiles'
  include ChecksConditionValidation
  include ChecksClientNotification
  include HasSearchIndexBackend
  include CanSelector
  include CanSearch
  include Report::Profile::Assets

  validates :name, presence: true
  store     :condition

  def self.list
    where(active: true)
  end

end
