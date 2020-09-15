# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Template < ApplicationModel
  include ChecksClientNotification

  belongs_to :user, optional: true

  store     :options
  validates :name, presence: true

  association_attributes_ignored :user
end
