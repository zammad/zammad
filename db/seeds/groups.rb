# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

Group.create_if_not_exists(
  id:            1,
  name:          'Users',
  signature_id:  Signature.first.id,
  note:          'Standard Group/Pool for Tickets.',
  updated_by_id: 1,
  created_by_id: 1
)
