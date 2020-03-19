class Controllers::GroupsControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.group')
end
