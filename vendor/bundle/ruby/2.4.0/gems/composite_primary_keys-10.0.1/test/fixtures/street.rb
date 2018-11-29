class Street < ActiveRecord::Base
  belongs_to :suburb,  :foreign_key => [:city_id, :suburb_id]
end