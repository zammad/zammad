// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import Mention, { type MentionOptions } from '@tiptap/extension-mention'
import { type Ref } from 'vue'

import buildMentionSuggestion from '#shared/components/Form/fields/FieldEditor/features/suggestions/suggestions.ts'
import type { FormFieldContext } from '#shared/components/Form/types/field.ts'
import { getNodeByName } from '#shared/components/Form/utils.ts'
import { ensureGraphqlId } from '#shared/graphql/utils.ts'
import { QueryHandler } from '#shared/server/apollo/handler/index.ts'
import { debouncedQuery, htmlCleanup } from '#shared/utils/helpers.ts'

import { useTextModuleSuggestionsLazyQuery } from '../graphql/queries/textModule/textModuleSuggestions.api.ts'

import type { FieldEditorProps, MentionTextItem } from '../types.ts'
import type { CommandProps } from '@tiptap/core'

export const PLUGIN_NAME = 'mentionText'
const ACTIVATOR = '::'

const LIMIT_QUERY_MODULES = 10

export default (context: Ref<FormFieldContext<FieldEditorProps>>) => {
  const queryHandler = new QueryHandler(useTextModuleSuggestionsLazyQuery({ query: '' }))

  const getTextModules = async (query: string) => {
    const { meta: editorMeta = {}, formId } = context.value

    const meta = editorMeta[PLUGIN_NAME] || {}
    const { ticketId } = context.value
    let { customerId, groupId } = context.value

    if (!customerId && meta.customerNodeName) {
      const node = getNodeByName(formId, meta.customerNodeName)
      customerId = node?.value as string
    }

    if (!groupId && meta.groupNodeName) {
      const node = getNodeByName(formId, meta.groupNodeName)
      groupId = node?.value as string
    }

    const { data } = await queryHandler.query({
      variables: {
        query,
        customerId: customerId ? ensureGraphqlId('User', customerId) : undefined,
        groupId: groupId ? ensureGraphqlId('Group', groupId) : undefined,
        ticketId: ticketId ? ensureGraphqlId('Ticket', ticketId) : undefined,
        limit: LIMIT_QUERY_MODULES,
      },
    })
    return data?.textModuleSuggestions || []
  }

  return Mention.extend({
    name: PLUGIN_NAME,
    addCommands: () => ({
      openTextMention:
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
      type: 'text',
      insert(item: MentionTextItem) {
        return htmlCleanup(item.renderedContent || '')
      },
      items: debouncedQuery(async ({ query }) => getTextModules(query), [], 200),
    }),
  })
}
