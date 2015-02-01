# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class TextModule < ApplicationModel
  validates       :name,    :presence => true
  validates       :content, :presence => true
  notify_clients_support
end