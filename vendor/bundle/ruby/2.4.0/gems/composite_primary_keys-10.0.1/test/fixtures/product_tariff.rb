class ProductTariff < ActiveRecord::Base
	self.primary_keys = :product_id, :tariff_id, :tariff_start_date
	belongs_to :product, :foreign_key => :product_id
	belongs_to :tariff,  :foreign_key => [:tariff_id, :tariff_start_date]
end
