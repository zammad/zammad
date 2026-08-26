// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { Link } from '#shared/types/router.ts'

import type { DropdownItem } from '#desktop/components/CommonDropdown/types.ts'
import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'

import type { KnowledgeBaseAnswerHeader, KnowledgeBaseBreadcrumbItem } from '../../types.ts'

export interface TopBarHeaderProps {
  locales: DropdownItem[]
  breadcrumbs: KnowledgeBaseBreadcrumbItem[]
  title?: Maybe<string>
  previewUrl?: Maybe<string>
  localeCode?: string
  actions?: MenuItem[]
  // There is nothing to copy while a node is being created - its title is a form field, not the
  //   heading the button would copy.
  noCopyButton?: boolean
  searchLink?: Link
}

// Caps the header rows that have to line up with the content below them:
//   `wide` matches the browse view's category/answer card grid, `reading` the
//   answer body's article column.
export type HeaderContentWidth = 'wide' | 'reading'

export type Navigation = NonNullable<KnowledgeBaseAnswerHeader['navigation']>
export interface AnswerNavigationEntry {
  link: Link
  label: string
}
