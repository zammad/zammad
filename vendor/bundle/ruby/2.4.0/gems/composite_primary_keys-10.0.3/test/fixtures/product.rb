class Product < ActiveRecord::Base
	self.primary_keys = :id  # redundant
	has_many :product_tariffs, :foreign_key => :product_id, :dependent => :delete_all
	has_many :tariffs, :through => :product_tariffs, :foreign_key => [:tariff_id, :tariff_start_date]

  has_and_belongs_to_many :restaurants,
    :foreign_key => :product_id,
    :association_foreign_key => [:franchise_id, :store_id]
end
