# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Template < ApplicationModel
  include ChecksClientNotification

  store     :options
  validates :name, presence: true
end
