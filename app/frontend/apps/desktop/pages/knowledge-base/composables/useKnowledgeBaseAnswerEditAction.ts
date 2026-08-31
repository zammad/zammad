// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed, toValue } from 'vue'
import { useRouter } from 'vue-router'

import { knowledgeBaseAnswerEditRoute } from '#desktop/entities/knowledge-base/utils/routeLocation.ts'

import type { KnowledgeBaseAnswerHeader } from '../types.ts'
import type { MaybeRefOrGetter } from 'vue'

type EditableAnswer = Pick<KnowledgeBaseAnswerHeader, 'id' | 'policy'>

// The way into the edit view, shared by the surfaces that offer it - the answer header's action
//   menu and the reader's floating toolbar - so the gate is stated once and both offer it under
//   exactly the same conditions.
export const useKnowledgeBaseAnswerEditAction = (options: {
  answer: MaybeRefOrGetter<EditableAnswer | undefined>
  // The locale being read, so editing continues in it: the edit route carries one, and its
  //   taskbar tab is per answer *and* locale.
  localeCode: MaybeRefOrGetter<string | undefined>
}) => {
  const router = useRouter()

  // Per record, never on the global `knowledge_base.editor` permission: granular setups routinely
  //   make someone editor of one subtree and reader elsewhere, and the global permission would
  //   offer a control the mutation then refuses. Per record is not per answer in practice -
  //   KnowledgeBase::AnswerPolicy#update? resolves the access of the answer's *category* - but it
  //   is the answer we hold here, and asking it costs nothing extra.
  const canEdit = computed(() => Boolean(toValue(options.answer)?.policy.update))

  const editAnswer = () => {
    const answer = toValue(options.answer)
    const localeCode = toValue(options.localeCode)

    if (!answer || !localeCode) return

    router.push(knowledgeBaseAnswerEditRoute(localeCode, answer.id))
  }

  return { canEdit, editAnswer }
}
