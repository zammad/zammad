// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { effectScope, ref } from 'vue'

import '#tests/graphql/builders/mocks.ts'

import type {
  FieldEditorProps,
  MentionKnowledgeBaseRelatedAnswers,
} from '#shared/components/Form/fields/FieldEditor/types.ts'
import type { FormFieldContext } from '#shared/components/Form/types/field.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import createKnowledgeBaseSuggestion from '../KnowledgeBaseSuggestion.ts'

import type { Editor } from '@tiptap/core'

const relatedAnswer = (id: number, title: string, maybeLocale?: string) => ({
  id: convertToGraphQLId('KnowledgeBase::Answer::Translation', id),
  title,
  maybeLocale,
  categoryTreeTranslation: [],
})

const relatedAnswers: MentionKnowledgeBaseRelatedAnswers = {
  linked: [relatedAnswer(1, 'VPN setup on company notebooks (Windows)')],
  suggested: [relatedAnswer(2, 'VPN troubleshooting', 'DE-DE')],
}

const getItemsBeforeTyping = async (answers?: MentionKnowledgeBaseRelatedAnswers) => {
  const context = ref({
    formId: 'form',
    meta: answers ? { mentionKnowledgeBase: { relatedAnswers: () => answers } } : {},
  } as unknown as FormFieldContext<FieldEditorProps>)

  const scope = effectScope()
  const extension = scope.run(() => createKnowledgeBaseSuggestion(context))!

  const items = await extension.options.suggestion.items!({
    query: '',
    editor: {} as Editor,
    signal: new AbortController().signal,
  })

  scope.stop()

  return items
}

describe('KnowledgeBaseSuggestion before a search term is typed', () => {
  it('offers the linked answers first and the suggested ones second', async () => {
    expect(await getItemsBeforeTyping(relatedAnswers)).toEqual([
      expect.objectContaining({
        title: 'VPN setup on company notebooks (Windows)',
        section: 'linked',
      }),
      expect.objectContaining({
        title: 'VPN troubleshooting',
        maybeLocale: 'DE-DE',
        section: 'suggested',
      }),
    ])
  })

  it('offers nothing without related answers', async () => {
    expect(await getItemsBeforeTyping()).toEqual([])
  })
})
