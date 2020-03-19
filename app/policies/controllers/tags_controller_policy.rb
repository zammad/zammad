class Controllers::TagsControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.tag')
end
