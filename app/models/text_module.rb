class TextModule < ApplicationModel
  validates   :name,    :presence => true
  validates   :content, :presence => true
end