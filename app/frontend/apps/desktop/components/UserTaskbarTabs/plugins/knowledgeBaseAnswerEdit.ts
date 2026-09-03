// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import {
  EnumTaskbarEntity,
  type KnowledgeBaseAnswerTaskbarTabAttributesFragment,
} from '#shared/graphql/types.ts'

import type { UserTaskbarTabPlugin } from '#desktop/components/UserTaskbarTabs/types.ts'
import { answerTaskbarTabKeyParts } from '#desktop/entities/knowledge-base/utils/taskbarTabKey.ts'

import KnowledgeBaseAnswerEdit from '../KnowledgeBase/KnowledgeBaseAnswerEdit.vue'

const entityType = 'KnowledgeBase::Answer'

export default <UserTaskbarTabPlugin>{
  type: EnumTaskbarEntity.KnowledgeBaseAnswerEdit,
  component: KnowledgeBaseAnswerEdit,
  entityType,
  // No `entityDocument`, so no entity is pre-filled from the cache while the tab is being created:
  //   that lookup addresses the entity by *its* id, and the entity of this tab is the translation
  //   of one locale - which the route names only by the answer's id and a locale code. The tab
  //   carries its static label for the one round trip until the taskbar list answers.
  // Must match Taskbar.entity_key(answer, locale) byte for byte, which is what the backend
  //   resolves the tab's entity from. `entityType.replaceAll` mirrors IdentifierName.encode - the
  //   locale is the qualifier that lets one answer have more than one tab, one per translation.
  buildEntityTabKey: (route) =>
    `${entityType.replaceAll('::', '__')}-${route.params.answerInternalId}-${route.params.localeCode}`,
  buildTaskbarTabEntityId: (route) => route.params.answerInternalId as string,
  buildTaskbarTabParams: (route) => ({
    answer_id: route.params.answerInternalId,
    locale: route.params.localeCode,
  }),
  // KnowledgeBaseAnswer carries no `internalId` field (unlike Ticket/User/Organization), so -
  //   entity loaded or not - the link is always rebuilt from the key alone: id *and* locale both
  //   live in it, the way `plugins/ticket.ts` falls back to `entityKey.split('-')` while its
  //   entity has not arrived yet.
  buildTaskbarTabLink: (
    _entity?: KnowledgeBaseAnswerTaskbarTabAttributesFragment,
    entityKey?: string,
  ) => {
    const parts = answerTaskbarTabKeyParts(entityKey)

    if (!parts) return undefined

    return `/knowledge-base/locale/${parts.localeCode}/answer/${parts.answerInternalId}/edit`
  },
  confirmTabRemove: true,
  touchExistingTab: true,
}
