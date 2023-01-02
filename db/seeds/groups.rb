# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

Group.create_if_not_exists(
  id:            1,
  name:          __('Users'),
  signature_id:  Signature.first.id,
  note:          __('Standard Group/Pool for Tickets.'),
  updated_by_id: 1,
  created_by_id: 1
)
