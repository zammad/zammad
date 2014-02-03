# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class TextModule < ApplicationModel
  validates       :name,    :presence => true
  validates       :content, :presence => true
  after_create    :notify_clients_after_create
  after_update    :notify_clients_after_update
  after_destroy   :notify_clients_after_destroy
end
