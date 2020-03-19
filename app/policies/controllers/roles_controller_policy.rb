class Controllers::RolesControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.role')
end
