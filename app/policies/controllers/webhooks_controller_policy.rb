class Controllers::WebhooksControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.webhook')
end
