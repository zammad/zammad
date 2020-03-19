class Controllers::Integration::ExchangeControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.integration.exchange')
end
