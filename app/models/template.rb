# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Template < ApplicationModel
  include ChecksClientNotification
  include Template::Assets

  store     :options
  validates :name, presence: true

  association_attributes_ignored :user
end
