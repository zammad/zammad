class Tariff < ActiveRecord::Base
	self.primary_keys = [:tariff_id, :start_date]
	has_many :product_tariffs, :foreign_key => [:tariff_id, :tariff_start_date], :dependent => :delete_all
	has_many :products, :through => :product_tariffs, :foreign_key => [:tariff_id, :tariff_start_date]
end
