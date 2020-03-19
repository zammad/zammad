class Controllers::PackagesControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.package')
end
