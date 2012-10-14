class Template < ApplicationModel
  store       :options
  validates   :name, :presence => true
end