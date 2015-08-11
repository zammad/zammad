# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Template < ApplicationModel
  store           :options
  validates       :name, presence: true
  notify_clients_support
end
