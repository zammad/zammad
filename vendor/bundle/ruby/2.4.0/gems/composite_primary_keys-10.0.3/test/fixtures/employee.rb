class Employee < ActiveRecord::Base
	belongs_to :department, :foreign_key => [:department_id, :location_id]
	has_many :comments, :as => :person
	has_and_belongs_to_many :groups
	has_many :salaries, :primary_key => [:id, :location_id],
		                  :foreign_key => [:employee_id, :location_id]
	has_one :one_salary, :class_name => "Salary",
		                   :primary_key => [:id, :location_id],
		                   :foreign_key => [:employee_id, :location_id]
end
