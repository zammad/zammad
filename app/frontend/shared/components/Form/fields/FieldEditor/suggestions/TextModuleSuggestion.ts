// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import Mention from '@tiptap/extension-mention'

import type { FormFieldContext } from '#shared/components/Form/types/field.ts'
import { getNodeByName } from '#shared/components/Form/utils.ts'
import { ensureGraphqlId } from '#shared/graphql/utils.ts'
import { QueryHandler } from '#shared/server/apollo/handler/index.ts'
import { debouncedQuery, htmlCleanup } from '#shared/utils/helpers.ts'

import { useTextModuleSuggestionsLazyQuery } from '../graphql/queries/textModule/textModuleSuggestions.api.ts'

import buildMentionSuggestion from './suggestions.ts'

import type { FieldEditorProps, MentionTextItem } from '../types.ts'
import type { Ref } from 'vue'

export const PLUGIN_NAME = 'mentionText'
const ACTIVATOR = '::'

const LIMIT_QUERY_MODULES = 10

export default (context: Ref<FormFieldContext<FieldEditorProps>>) => {
  const queryHandler = new QueryHandler(
    useTextModuleSuggestionsLazyQuery({ query: '' }),
  )

  const getTextModules = async (query: string) => {
    const { meta: editorMeta = {}, formId } = context.value

    const meta = editorMeta[PLUGIN_NAME] || {}
    let { ticketId, customerId } = context.value

    if (!ticketId && meta.ticketNodeName) {
      const node = getNodeByName(formId, meta.ticketNodeName)
      ticketId = node?.value as string
    }

    if (!customerId && meta.customerNodeName) {
      const node = getNodeByName(formId, meta.customerNodeName)
      customerId = node?.value as string
    }

    const { data } = await queryHandler.query({
      variables: {
        query,
        customerId: customerId && ensureGraphqlId('User', customerId),
        ticketId: ticketId && ensureGraphqlId('Ticket', ticketId),
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
        ({ chain }) =>
          chain().insertContent(` ${ACTIVATOR}`).run(),
    }),
  }).configure({
    suggestion: buildMentionSuggestion({
      activator: ACTIVATOR,
      type: 'text',
      insert(item: MentionTextItem) {
        return htmlCleanup(item.renderedContent || '')
      },
      items: debouncedQuery(async ({ query }) => {
        if (!query) {
          return []
        }
        return getTextModules(query)
      }, []),
    }),
  })
}
