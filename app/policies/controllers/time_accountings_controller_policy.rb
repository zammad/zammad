class Controllers::TimeAccountingsControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.time_accounting')
end
