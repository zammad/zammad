// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed } from 'vue'

import type { FieldEditorContext } from '#shared/components/Form/fields/FieldEditor/types.ts'

import { useTicketInformation } from '#desktop/pages/ticket/composables/useTicketInformation.ts'

// Inserting an answer into the article being written. It never opens an article by itself.
export const useKnowledgeBaseAnswerInsert = () => {
  const { form, isTicketEditable, newTicketArticlePresent } = useTicketInformation()

  const canInsertAnswer = computed(() => isTicketEditable.value && !!newTicketArticlePresent.value)

  const insertAnswer = (translationId: ID) => {
    const context = form.value?.getNodeByName('body')?.context as FieldEditorContext | undefined

    context?.insertKnowledgeBaseAnswer?.(translationId)
  }

  return {
    canInsertAnswer,
    insertAnswer,
  }
}
