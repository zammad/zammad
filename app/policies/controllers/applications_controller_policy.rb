class Controllers::ApplicationsControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.api')
end
