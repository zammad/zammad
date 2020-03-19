class Controllers::GettingStartedControllerPolicy < Controllers::ApplicationControllerPolicy
  permit! :base, to: 'admin.wizard'
end
