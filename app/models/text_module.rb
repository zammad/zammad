# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

class TextModule < ApplicationModel
  validates   :name,    :presence => true
  validates   :content, :presence => true
end
