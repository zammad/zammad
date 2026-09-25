// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { PageRoute } from './navigationItems.ts'

// Props a route's own navigation entry (`meta.navigationItemComponent`) receives.
export interface NavigationItemComponentProps {
  route: PageRoute
  collapsed: boolean
  active: boolean
}
