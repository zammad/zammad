// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { BreadcrumbItem } from '#desktop/components/CommonBreadcrumb/types.ts'
import type { DropdownItem } from '#desktop/components/CommonDropdown/types.ts'

export interface TopBarHeaderProps {
  locales: DropdownItem[]
  breadcrumbs: BreadcrumbItem[]
  title?: Maybe<string>
  previewUrl?: Maybe<string>
  localeCode?: string
}
