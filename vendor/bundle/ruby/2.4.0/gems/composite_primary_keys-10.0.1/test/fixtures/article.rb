class Article < ActiveRecord::Base
  validates :id, uniqueness: true, numericality: true, allow_nil: true, allow_blank: true, on: :create
  has_many :readings, :dependent => :delete_all
  has_many :users, :through => :readings
end

