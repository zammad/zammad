# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class SystemReport::Plugin::Entities::User < SystemReport::Plugin
  DESCRIPTION = __('Customer and agent ratio (role based user counts)').freeze

  def fetch
    {
      'Agents'    => User.with_permissions('ticket.agent').count,
      'Customer'  => User.with_permissions('ticket.customer').count,
      'LastLogin' => User.maximum(:last_login),
    }
  end
end
