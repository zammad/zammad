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

  // Skeletons the rows that are fed from the record, while keeping the header itself mounted.
  //   For the edit view, whose header cannot be swapped for `TopBarHeaderFullSkeleton` the way the
  //   reader's is: it carries the form's teleported title field, which resolves its target once,
  //   so unmounting the header takes the field with it for the life of that form.
  loading?: boolean
}

// Caps the header rows that have to line up with the content below them:
//   `wide` matches the browse view's category/answer card grid, `reading` the
//   answer body's article column, `form` the create/edit form's column.
export type HeaderContentWidth = 'wide' | 'reading' | 'form'

export type Navigation = NonNullable<KnowledgeBaseAnswerHeader['navigation']>
export interface AnswerNavigationEntry {
  link: Link
  label: string
}

// What the badge/chip row (KnowledgeBaseAnswerHeaderDetails.vue) needs - `visibility` is the only
//   part every caller has: the create header has nothing else yet, since none of the rest exists
//   before the draft is ever saved.
export type KnowledgeBaseAnswerHeaderDetailsAnswer = Pick<KnowledgeBaseAnswerHeader, 'visibility'> &
  Partial<
    Pick<
      KnowledgeBaseAnswerHeader,
      | 'translationMissing'
      | 'internalAt'
      | 'publishedAt'
      | 'archivedAt'
      | 'editedAt'
      | 'editedBy'
      | 'visibilitySchedules'
    >
  >
