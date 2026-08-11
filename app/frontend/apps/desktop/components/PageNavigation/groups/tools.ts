// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { NavigationGroup } from '#desktop/components/PageNavigation/navigationGroups.ts'

// Counterpart of the legacy `#tools` navigation bar parent, which addons like
//   TimeTracking and ProjectBaller nest their entries under.
const group: NavigationGroup = {
  key: 'tools',
  title: __('Tools'),
  icon: 'wrench',
  order: 90000,
}

export default group
