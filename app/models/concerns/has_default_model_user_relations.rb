# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module HasDefaultModelUserRelations
  extend ActiveSupport::Concern

  included do
    belongs_to :created_by, class_name: 'User'
    belongs_to :updated_by, class_name: 'User'
  end
end
