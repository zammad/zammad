# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

Channel.create_if_not_exists(
  area:        'Email::Notification',
  options:     {
    outbound: {
      adapter: 'smtp',
      options: {
        host:     'host.example.com',
        user:     '',
        password: '',
        ssl:      true,
      },
    },
  },
  group_id:    1,
  preferences: { online_service_disable: true },
  active:      false,
)
Channel.create_if_not_exists(
  area:        'Email::Notification',
  options:     {
    outbound: {
      adapter: 'sendmail',
    },
  },
  preferences: { online_service_disable: true },
  active:      true,
)
