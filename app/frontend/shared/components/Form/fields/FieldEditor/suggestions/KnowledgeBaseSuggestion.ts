// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import Mention from '@tiptap/extension-mention'
import { cloneDeep } from 'lodash-es'

import type { FormFieldContext } from '#shared/components/Form/types/field.ts'
import { getNodeByName } from '#shared/components/Form/utils.ts'
import type { StoredFile } from '#shared/graphql/types.ts'
import {
  MutationHandler,
  QueryHandler,
} from '#shared/server/apollo/handler/index.ts'
import { debouncedQuery, htmlCleanup } from '#shared/utils/helpers.ts'

import { useKnowledgeBaseAnswerSuggestionContentTransformMutation } from '../graphql/mutations/knowledgeBase/suggestion/content/transform.api.ts'
import { useKnowledgeBaseAnswerSuggestionsLazyQuery } from '../graphql/queries/knowledgeBase/answerSuggestions.api.ts'

import buildMentionSuggestion from './suggestions.ts'

import type { FieldEditorProps, MentionKnowledgeBaseItem } from '../types.ts'
import type { Ref } from 'vue'

export const PLUGIN_NAME = 'mentionKnowledgeBase'
const ACTIVATOR = '??'

export default (context: Ref<FormFieldContext<FieldEditorProps>>) => {
  const queryHandler = new QueryHandler(
    useKnowledgeBaseAnswerSuggestionsLazyQuery({
      query: '',
    }),
  )

  const getKnowledgeBaseMentions = async (query: string) => {
    const { data } = await queryHandler.query({ variables: { query } })
    return data?.knowledgeBaseAnswerSuggestions || []
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
      async insert(props: MentionKnowledgeBaseItem) {
        const { meta: editorMeta = {}, formId } = context.value
        const meta = editorMeta[PLUGIN_NAME] || {}

        const result = await translateHandler.send({
          translationId: props.id,
          formId,
        })

        const attachmentsNodeName = meta?.attachmentsNodeName

        if (attachmentsNodeName) {
          const attachmentField = getNodeByName(
            context.value.formId,
            attachmentsNodeName,
          )

          const existingAttachments = (cloneDeep(attachmentField?.value) ||
            []) as StoredFile[]
          const newAttachments =
            result?.knowledgeBaseAnswerSuggestionContentTransform
              ?.attachments || []

          attachmentField?.input?.([...existingAttachments, ...newAttachments])
        }

        return htmlCleanup(
          result?.knowledgeBaseAnswerSuggestionContentTransform?.body || '',
        )
      },
      items: debouncedQuery(async ({ query }) => {
        if (!query) {
          return []
        }
        return getKnowledgeBaseMentions(query)
      }, []),
    }),
  })
}
