// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import Mention from '@tiptap/extension-mention'

import type { Ref } from 'vue'
import type { FormFieldContext } from '@shared/components/Form/types/field'
import { QueryHandler } from '@shared/server/apollo/handler'
import { ensureGraphqlId } from '@shared/graphql/utils'
import { debouncedQuery } from '@shared/utils/helpers'
import { getNodeByName } from '@shared/components/Form/utils'
import type { FieldEditorProps, MentionTextItem } from '../types'
import buildMentionSuggestion from './suggestions'
import { useTextModuleSuggestionsLazyQuery } from '../graphql/queries/textModule/textModuleSuggestions.api'

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
      query,
      customerId: customerId && ensureGraphqlId('User', customerId),
      ticketId: ticketId && ensureGraphqlId('Ticket', ticketId),
      limit: LIMIT_QUERY_MODULES,
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
        return item.renderedContent || ''
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
