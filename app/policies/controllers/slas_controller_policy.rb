class Controllers::SlasControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.sla')
end
