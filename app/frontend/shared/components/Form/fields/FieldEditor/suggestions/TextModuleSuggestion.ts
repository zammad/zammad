// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import Mention from '@tiptap/extension-mention'

import { replaceTags } from '@shared/utils/formatter'

import type { CommandTextProps, MentionTextItem } from '../types'
import buildMentionSuggestion from './suggestions'

const ACTIVATOR = '::'

const findTextItems = (query: string): MentionTextItem[] => {
  return [
    {
      title: 'MySnap',
      content: `Hello Mrs. #{ticket.customer.lastname} - query "${query}"`,
      id: '1',
      keyword: 'keyword',
    },
  ]
}

// TODO
export default Mention.extend({
  name: 'mention-text',
  addCommands() {
    return {
      openTextMention:
        () =>
        ({ chain }) => {
          return chain().insertContent(` ${ACTIVATOR}`).run()
        },
    }
  },
}).configure({
  suggestion: buildMentionSuggestion({
    activator: ACTIVATOR,
    type: 'text',
    insert(item: CommandTextProps) {
      // TODO maybe it's better to replace it on the backend
      return replaceTags(item.content, {
        ticket: { customer: { lastname: 'name' } },
      })
    },
    items: ({ query }) => findTextItems(query),
  }),
})
