# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Template < ApplicationModel
  include ChecksClientNotification

  store     :options
  validates :name, presence: true

  association_attributes_ignored :user
end
