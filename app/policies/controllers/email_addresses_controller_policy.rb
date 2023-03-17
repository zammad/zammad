# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Controllers::EmailAddressesControllerPolicy < Controllers::ApplicationControllerPolicy
  permit! %i[index show], to: ['ticket.agent', 'admin.channel_email']
  default_permit!('admin.channel_email')
end
