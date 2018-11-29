class Salary < ActiveRecord::Base
  belongs_to :employee,
    :primary_key => [:id, :location_id],
    :foreign_key => [:employee_id, :location_id]
end
