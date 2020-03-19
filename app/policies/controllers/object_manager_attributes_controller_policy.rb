class Controllers::ObjectManagerAttributesControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.object')
end
