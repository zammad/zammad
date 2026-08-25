// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import {
  EnumTaskbarEntity,
  type UserTaskbarItemEntityKnowledgeBaseAnswerCreate,
} from '#shared/graphql/types.ts'

import type { UserTaskbarTabPlugin } from '#desktop/components/UserTaskbarTabs/types.ts'

import KnowledgeBaseAnswerCreate from '../KnowledgeBase/KnowledgeBaseAnswerCreate.vue'

export default <UserTaskbarTabPlugin>{
  type: EnumTaskbarEntity.KnowledgeBaseAnswerCreate,
  component: KnowledgeBaseAnswerCreate,
  // The 'Screen' suffix keeps the key of a draft apart from the key of a stored answer
  //   ('KnowledgeBase__Answer-42'), which the edit view uses - the backend branches on exactly
  //   this prefix (Gql::Types::User::TaskbarItemType#object_entity!).
  buildEntityTabKey: (route) => `KnowledgeBaseAnswerCreateScreen-${route.params.tabId}`,
  buildTaskbarTabEntityId: (route) => route.params.tabId as string,
  // The locale is stored with the tab because the link below has to be rebuildable without
  //   loading the form, and because it never changes for a tab - one draft is one translation.
  //
  // The category is deliberately *not* here: these params are written once, when the tab is
  //   created, and never updated (the store only ever sends `state` afterwards), so a copy of the
  //   category could only ever name the one the draft was opened from. The live value belongs to
  //   the draft state, which the auto-save keeps; the URL query seeds the first render.
  buildTaskbarTabParams: (route) => ({
    id: route.params.tabId,
    locale: route.params.localeCode,
  }),
  buildTaskbarTabLink: (entity?: UserTaskbarItemEntityKnowledgeBaseAnswerCreate) => {
    if (!entity?.uid || !entity.locale) return

    return `/knowledge-base/locale/${entity.locale}/answer/create/${entity.uid}`
  },
  confirmTabRemove: true,
}
