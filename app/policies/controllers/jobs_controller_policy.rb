class Controllers::JobsControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.scheduler')
end
