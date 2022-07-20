// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import Mention from '@tiptap/extension-mention'

import buildMentionSuggestion from './suggestions'
import type {
  CommandKnowledgeBaseProps,
  MentionKnowledgeBaseItem,
} from '../types'

const ACTIVATOR = '??'

const findKnowledgeBaseItems = async (
  query: string,
): Promise<MentionKnowledgeBaseItem[]> => {
  return [
    {
      title: 'Title1',
      category: 'Category',
      content: 'CONTENT',
      id: '3',
    },
    {
      title: 'Title2',
      category: 'Category',
      content: query,
      id: '4',
    },
  ]
}

export default Mention.extend({
  name: 'mention-knowledge-base',
  addCommands() {
    return {
      openKnowledgeBaseMention:
        () =>
        ({ chain }) => {
          return chain().insertContent(` ${ACTIVATOR}`).run()
        },
    }
  },
}).configure({
  suggestion: buildMentionSuggestion({
    activator: '??',
    type: 'knowledge-base',
    insert(props: CommandKnowledgeBaseProps) {
      return props.content
    },
    items({ query }) {
      return findKnowledgeBaseItems(query)
    },
  }),
})
