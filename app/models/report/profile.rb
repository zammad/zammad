# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Report::Profile < ApplicationModel
  self.table_name = 'report_profiles'
  include ChecksConditionValidation
  include ChecksClientNotification
  include HasSearchIndexBackend
  include CanSelector
  include CanSearch
  include Report::Profile::Assets

  has_and_belongs_to_many :roles, after_add: :cache_update, after_remove: :cache_update, class_name: 'Role'

  validates :name, presence: true
  store     :condition

  def self.list
    where(active: true)
  end

end
