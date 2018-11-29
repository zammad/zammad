class Department < ActiveRecord::Base
  self.primary_keys = :department_id, :location_id
  has_many :employees, :foreign_key => [:department_id, :location_id]
  has_one :head, :class_name => 'Employee', :foreign_key => [:department_id, :location_id], :dependent => :delete
end
