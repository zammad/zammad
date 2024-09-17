// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'

export type DropdownItem = Omit<MenuItem, 'onClick'>
