class Signature < ApplicationModel
  has_many                :groups,  :after_add => :cache_update, :after_remove => :cache_update
  validates               :name,    :presence => true
end
