// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import Mention from '@tiptap/extension-mention'

import { MutationHandler, QueryHandler } from '@shared/server/apollo/handler'
import type { Ref } from 'vue'
import type { FormFieldContext } from '@shared/components/Form/types/field'
import { useKnowledgeBaseAnswerSuggestionsLazyQuery } from '../graphql/queries/knowledgeBase/answerSuggestions.api'
import buildMentionSuggestion from './suggestions'
import { useKnowledgeBaseAnswerSuggestionContentTransformMutation } from '../graphql/mutations/knowledgeBase/suggestion/content/transform.api'
import type { MentionKnowledgeBaseItem } from '../types'

export const PLUGIN_NAME = 'mentionKnowledgeBase'
const ACTIVATOR = '??'

export default (context: Ref<FormFieldContext>) => {
  const queryHandler = new QueryHandler(
    useKnowledgeBaseAnswerSuggestionsLazyQuery({
      query: '',
    }),
  )

  const getKnowledgeBaseMentions = async (query: string) => {
    const result = await queryHandler.trigger({ query })
    return result?.knowledgeBaseAnswerSuggestions || []
  }

  const translateHandler = new MutationHandler(
    useKnowledgeBaseAnswerSuggestionContentTransformMutation({}),
  )

  return Mention.extend({
    name: PLUGIN_NAME,
    addCommands: () => ({
      openKnowledgeBaseMention:
        () =>
        ({ chain }) =>
          chain().insertContent(` ${ACTIVATOR}`).run(),
    }),
  }).configure({
    suggestion: buildMentionSuggestion({
      activator: ACTIVATOR,
      allowSpaces: true,
      type: 'knowledge-base',
      // TODO: possible race condition
      async insert(props: MentionKnowledgeBaseItem) {
        const result = await translateHandler.send({
          translationId: props.id,
          formId: context.value.formId,
        })
        // TODO process attachments, use meta[PLUGIN_NAME].attachmentsNodeId
        return result?.knowledgeBaseAnswerSuggestionContentTransform?.body || ''
      },
      async items({ query }) {
        if (!query) {
          return []
        }
        return getKnowledgeBaseMentions(query)
      },
    }),
  })
}
