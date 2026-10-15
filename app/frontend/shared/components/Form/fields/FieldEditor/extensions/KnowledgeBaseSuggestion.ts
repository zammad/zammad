// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import Mention, { type MentionOptions } from '@tiptap/extension-mention'
import { cloneDeep } from 'lodash-es'

import {
  claimInlineImages,
  getEditorFormId,
} from '#shared/components/Form/fields/FieldEditor/features/image-handler/inlineImageUploads.ts'
import buildMentionSuggestion from '#shared/components/Form/fields/FieldEditor/features/suggestions/suggestions.ts'
import type { FormFieldContext } from '#shared/components/Form/types/field.ts'
import { getNodeByName } from '#shared/components/Form/utils.ts'
import type { StoredFile } from '#shared/graphql/types.ts'
import { MutationHandler, QueryHandler } from '#shared/server/apollo/handler/index.ts'
import { debouncedQuery, htmlCleanup } from '#shared/utils/helpers.ts'

import { useKnowledgeBaseAnswerSuggestionContentTransformMutation } from '../graphql/mutations/knowledgeBase/suggestion/content/transform.api.ts'
import { useKnowledgeBaseAnswerSuggestionsLazyQuery } from '../graphql/queries/knowledgeBase/answerSuggestions.api.ts'

import type {
  FieldEditorProps,
  MentionKnowledgeBaseItem,
  MentionKnowledgeBaseRelatedAnswer,
  MentionKnowledgeBaseRelatedItem,
  MentionKnowledgeBaseRelatedSection,
} from '../types.ts'
import type { CommandProps, EditorEvents } from '@tiptap/core'
import type { Ref } from 'vue'

export const EXTENSION_NAME = 'mentionKnowledgeBase'

const ACTIVATOR = '??'

const toRelatedMention = (
  answer: MentionKnowledgeBaseRelatedAnswer,
  section: MentionKnowledgeBaseRelatedSection,
): MentionKnowledgeBaseRelatedItem => ({ ...answer, section })

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

  const searchKnowledgeBaseMentions = debouncedQuery(
    async ({ query }: { query: string }) => getKnowledgeBaseMentions(query),
    [],
    200,
  )

  // Offered before a search term is typed: the answers linked to the edited record first, then the
  //   suggested ones.
  const getRelatedMentions = (): MentionKnowledgeBaseRelatedItem[] => {
    const relatedAnswers = context.value.meta?.[EXTENSION_NAME]?.relatedAnswers?.()
    if (!relatedAnswers) return []

    return [
      ...relatedAnswers.linked.map((answer) => toRelatedMention(answer, 'linked')),
      ...relatedAnswers.suggested.map((answer) => toRelatedMention(answer, 'suggested')),
    ]
  }

  const translateHandler = new MutationHandler(
    useKnowledgeBaseAnswerSuggestionContentTransformMutation({}),
  )

  // Shared by `??` and the insert from outside the editor, so both bring the same content.
  //   Attachments are only added while the editor that asked for them is still there.
  const loadAnswerContent = async (translationId: ID, isEditorAlive = () => true) => {
    const { meta: editorMeta = {}, formId } = context.value
    const meta = editorMeta[EXTENSION_NAME] || {}

    const result = await translateHandler.send({
      translationId,
      formId,
    })

    if (!isEditorAlive()) return ''

    const attachmentsNodeName = meta?.attachmentsNodeName

    if (attachmentsNodeName) {
      const attachmentField = getNodeByName(context.value.formId, attachmentsNodeName)

      const existingAttachments = (cloneDeep(attachmentField?.value) || []) as StoredFile[]
      const newAttachments =
        result?.knowledgeBaseAnswerSuggestionContentTransform?.attachments || []

      attachmentField?.input?.([...existingAttachments, ...newAttachments])
    }

    return htmlCleanup(result?.knowledgeBaseAnswerSuggestionContentTransform?.body || '')
  }

  return Mention.extend({
    name: EXTENSION_NAME,
    addCommands: () => ({
      openKnowledgeBaseMention:
        () =>
        // TODO: Check if this explicit typing is still needed after the stable release of next TipTap version.
        ({ chain }: CommandProps) =>
          chain().insertContent(` ${ACTIVATOR}`).run(),
      insertKnowledgeBaseAnswer:
        (translationId: ID) =>
        ({ editor, dispatch }: CommandProps) => {
          if (!dispatch) return true

          // Taken now, so the answer replaces the current selection. Text typed at either edge while the
          //   content loads stays outside the replaced range.
          let { from, to } = editor.state.selection

          const trackPosition = ({
            transaction,
            appendedTransactions,
          }: EditorEvents['transaction']) => {
            ;[transaction, ...appendedTransactions].forEach((tr) => {
              from = tr.mapping.map(from)
              to = Math.max(from, tr.mapping.map(to, -1))
            })
          }

          editor.on('transaction', trackPosition)

          loadAnswerContent(translationId, () => !editor.isDestroyed)
            .then((content) => {
              if (!content || editor.isDestroyed) return

              claimInlineImages(getEditorFormId(editor), content)
              editor.chain().focus().insertContentAt({ from, to }, content).run()
            })
            // A failed request is already notified by the handler, and inserts nothing.
            .catch(() => {})
            .finally(() => editor.off('transaction', trackPosition))

          return true
        },
    }),
    addOptions() {
      return {
        ...(this as unknown as { parent: () => MentionOptions }).parent?.(),
        permission: 'ticket.agent',
      }
    },
  }).configure({
    suggestion: buildMentionSuggestion<MentionKnowledgeBaseItem | MentionKnowledgeBaseRelatedItem>({
      activator: ACTIVATOR,
      type: 'knowledge-base',
      label: __('Knowledge base articles'),
      placeholder: __('Start typing to search in knowledge base…'),
      insert: (props: MentionKnowledgeBaseItem | MentionKnowledgeBaseRelatedItem) =>
        loadAnswerContent(props.id),
      // The related answers are at hand, so they skip the debounce. A search still on its way when the
      //   term is cleared is discarded by the suggestion plugin.
      items: ({ query }) => (query ? searchKnowledgeBaseMentions({ query }) : getRelatedMentions()),
      // The related answers may still be loading when `??` opens.
      defaultListSource: getRelatedMentions,
    }),
  })
}
