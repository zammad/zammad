# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

Report::Profile.create_if_not_exists(
  name:          '-all-',
  condition:     {},
  active:        true,
  updated_by_id: 1,
  created_by_id: 1,
)
