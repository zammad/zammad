class Controllers::TriggersControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.trigger')
end
