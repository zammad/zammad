// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import {
  EnumTaskbarEntity,
  type KnowledgeBaseAnswerTaskbarTabAttributesFragment,
} from '#shared/graphql/types.ts'

import type { UserTaskbarTabPlugin } from '#desktop/components/UserTaskbarTabs/types.ts'
import { KnowledgeBaseAnswerTaskbarTabAttributesFragmentDoc } from '#desktop/entities/knowledge-base/graphql/fragments/knowledgeBaseAnswerTaskbarTabAttributes.api.ts'

import KnowledgeBaseAnswerEdit from '../KnowledgeBase/KnowledgeBaseAnswerEdit.vue'

const entityType = 'KnowledgeBase::Answer'

export default <UserTaskbarTabPlugin>{
  type: EnumTaskbarEntity.KnowledgeBaseAnswerEdit,
  component: KnowledgeBaseAnswerEdit,
  entityType,
  entityDocument: KnowledgeBaseAnswerTaskbarTabAttributesFragmentDoc,
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
    if (!entityKey) return undefined

    // 'KnowledgeBase__Answer-42-de-de': the id segment never contains a '-', the locale after it
    //   always does (e.g. 'de-de'), so taking everything past the id is unambiguous.
    const [, answerInternalId, ...localeParts] = entityKey.split('-')

    if (!answerInternalId || localeParts.length === 0) return undefined

    return `/knowledge-base/locale/${localeParts.join('-')}/answer/${answerInternalId}/edit`
  },
  confirmTabRemove: true,
  touchExistingTab: true,
}
