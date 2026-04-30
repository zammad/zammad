// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import Mention, { type MentionOptions } from '@tiptap/extension-mention'
import { cloneDeep } from 'lodash-es'

import buildMentionSuggestion from '#shared/components/Form/fields/FieldEditor/features/suggestions/suggestions.ts'
import type { FormFieldContext } from '#shared/components/Form/types/field.ts'
import { getNodeByName } from '#shared/components/Form/utils.ts'
import type { StoredFile } from '#shared/graphql/types.ts'
import { MutationHandler, QueryHandler } from '#shared/server/apollo/handler/index.ts'
import { debouncedQuery, htmlCleanup } from '#shared/utils/helpers.ts'

import { useKnowledgeBaseAnswerSuggestionContentTransformMutation } from '../graphql/mutations/knowledgeBase/suggestion/content/transform.api.ts'
import { useKnowledgeBaseAnswerSuggestionsLazyQuery } from '../graphql/queries/knowledgeBase/answerSuggestions.api.ts'

import type { FieldEditorProps, MentionKnowledgeBaseItem } from '../types.ts'
import type { CommandProps } from '@tiptap/core'
import type { Ref } from 'vue'

export const EXTENSION_NAME = 'mentionKnowledgeBase'

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
    name: EXTENSION_NAME,
    addCommands: () => ({
      openKnowledgeBaseMention:
        () =>
        // TODO: Check if this explicit typing is still needed after the stable release of next TipTap version.
        ({ chain }: CommandProps) =>
          chain().insertContent(` ${ACTIVATOR}`).run(),
    }),
    addOptions() {
      return {
        ...(this as unknown as { parent: () => MentionOptions }).parent?.(),
        permission: 'ticket.agent',
      }
    },
  }).configure({
    suggestion: buildMentionSuggestion({
      activator: ACTIVATOR,
      type: 'knowledge-base',
      async insert(props: MentionKnowledgeBaseItem) {
        const { meta: editorMeta = {}, formId } = context.value
        const meta = editorMeta[EXTENSION_NAME] || {}

        const result = await translateHandler.send({
          translationId: props.id,
          formId,
        })

        const attachmentsNodeName = meta?.attachmentsNodeName

        if (attachmentsNodeName) {
          const attachmentField = getNodeByName(context.value.formId, attachmentsNodeName)

          const existingAttachments = (cloneDeep(attachmentField?.value) || []) as StoredFile[]
          const newAttachments =
            result?.knowledgeBaseAnswerSuggestionContentTransform?.attachments || []

          attachmentField?.input?.([...existingAttachments, ...newAttachments])
        }

        return htmlCleanup(result?.knowledgeBaseAnswerSuggestionContentTransform?.body || '')
      },
      items: debouncedQuery(
        async ({ query }) => {
          if (!query) return []
          return getKnowledgeBaseMentions(query)
        },
        [],
        200,
      ),
    }),
  })
}
