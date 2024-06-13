// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { initializePopoverPosition } from '#shared/initializer/initializePopover.ts'

export const initializeGlobalComponentConfigurations = () => {
  initializePopoverPosition('custom')
}
