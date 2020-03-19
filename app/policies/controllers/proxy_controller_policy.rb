class Controllers::ProxyControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.system')
end
