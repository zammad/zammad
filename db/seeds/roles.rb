Role.create_if_not_exists(
  id:                1,
  name:              'Admin',
  note:              'To configure your system.',
  preferences:       {
    not: ['Customer'],
  },
  default_at_signup: false,
  updated_by_id:     1,
  created_by_id:     1
)
Role.create_if_not_exists(
  id:                2,
  name:              'Agent',
  note:              'To work on Tickets.',
  default_at_signup: false,
  preferences:       {
    not: ['Customer'],
  },
  updated_by_id:     1,
  created_by_id:     1
)
Role.create_if_not_exists(
  id:                3,
  name:              'Customer',
  note:              'People who create Tickets ask for help.',
  preferences:       {
    not: %w[Agent Admin],
  },
  default_at_signup: true,
  updated_by_id:     1,
  created_by_id:     1
)
