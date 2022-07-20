// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import Mention from '@tiptap/extension-mention'
import Link from '@tiptap/extension-link'

import buildMentionSuggestion from './suggestions'
import type { CommandUserProps, MentionUserItem } from '../types'

const LINK_NAME = 'mention-user-link'
const ACTIVATOR = '@@'

const findUsers = async (query: string): Promise<MentionUserItem[]> => {
  return [
    { firstname: 'Bob', lastname: 'Wance', email: 'some@email.com', id: '3' },
    { firstname: 'Robin', lastname: 'Hood', id: '2' },
    { firstname: 'Robert', lastname: 'California', id: '1' },
    { firstname: query, id: '4' },
  ]
}

export default Mention.extend({
  name: 'mention-user',
  addCommands() {
    return {
      openUserMention:
        () =>
        ({ chain }) => {
          return chain().insertContent(` ${ACTIVATOR}`).run()
        },
    }
  },
}).configure({
  suggestion: buildMentionSuggestion({
    activator: ACTIVATOR,
    type: 'user',
    insert(props: CommandUserProps) {
      return [
        {
          type: 'text',
          text: props.title,
          marks: [
            {
              type: LINK_NAME,
              attrs: {
                href: props.href,
                'data-mention-user-id': props.id,
              },
            },
          ],
        },
      ]
    },
    items: ({ query }) => findUsers(query),
  }),
})

export const UserLink = Link.extend({
  name: LINK_NAME,
  addAttributes() {
    return {
      href: {
        default: null,
      },
      'data-mention-user-id': {
        default: null,
        parseHTML: (element) => element.getAttribute('data-mention-user-id'),
        renderHTML: (attributes) => {
          return {
            'data-mention-user-id': attributes['data-mention-user-id'],
          }
        },
      },
    }
  },
}).configure({
  openOnClick: false,
  autolink: false,
})
