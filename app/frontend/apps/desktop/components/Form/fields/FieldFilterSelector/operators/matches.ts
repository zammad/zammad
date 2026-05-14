// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { Operator } from '../types.ts'

export default <Operator>{
  name: 'matches',
  label: __('matches'),
  filterFields: [{ type: 'text', delay: 500 }],
}
