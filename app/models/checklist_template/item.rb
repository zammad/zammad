# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class ChecklistTemplate::Item < ApplicationModel
  include ChecksClientNotification
  include HasDefaultModelUserRelations

  belongs_to :checklist_template

  # MySQL does not support default value on non-null text columns
  # Can be removed after dropping MySQL
  before_validation :ensure_text_not_nil, if: -> { ActiveRecord::Base.connection_db_config.configuration_hash[:adapter] == 'mysql2' }

  private

  # MySQL does not support default value on non-null text columns
  # Can be removed after dropping MySQL
  def ensure_text_not_nil
    self.text ||= ''
  end
end
