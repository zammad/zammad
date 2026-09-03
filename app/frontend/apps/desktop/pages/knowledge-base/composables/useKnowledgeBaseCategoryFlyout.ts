// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { openFlyout, useFlyout } from '#desktop/components/CommonFlyout/useFlyout.ts'

import type { EditableKnowledgeBaseCategory } from '../types.ts'

const FLYOUT_NAME = 'knowledge-base-category'

// Split like `useUserEdit`: registering the flyout needs a setup scope, opening it does
//   not. `useKnowledgeBaseCategoryFlyout` is therefore called exactly once — in
//   KnowledgeBaseBrowse.vue, which renders both browse routes and survives the root ↔
//   category switch by being the same component either side of it — while the entry points
//   scattered below it (the add card, the floating toolbar, the header and card menus) just
//   call the functions below.
export const openKnowledgeBaseCategoryAddFlyout = (options: { parentId?: string } = {}) =>
  openFlyout(FLYOUT_NAME, {
    name: FLYOUT_NAME,
    parentId: options.parentId,
  })

export const openKnowledgeBaseCategoryEditFlyout = (category: EditableKnowledgeBaseCategory) =>
  openFlyout(FLYOUT_NAME, {
    name: FLYOUT_NAME,
    category,
  })

export const useKnowledgeBaseCategoryFlyout = () => {
  useFlyout({
    name: FLYOUT_NAME,
    component: () =>
      import('#desktop/pages/knowledge-base/components/KnowledgeBaseCategoryFlyout/KnowledgeBaseCategoryFlyout.vue'),
  })

  return { openKnowledgeBaseCategoryAddFlyout, openKnowledgeBaseCategoryEditFlyout }
}
