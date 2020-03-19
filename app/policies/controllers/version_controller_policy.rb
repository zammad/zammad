class Controllers::VersionControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.version')
end
