class Controllers::ReportsControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('report')
end
