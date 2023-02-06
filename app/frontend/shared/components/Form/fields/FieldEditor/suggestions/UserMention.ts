// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import Mention from '@tiptap/extension-mention'
import Link from '@tiptap/extension-link'
import type { Ref } from 'vue'
import type { FormFieldContext } from '@shared/components/Form/types/field'
import { QueryHandler } from '@shared/server/apollo/handler'
import {
  NotificationTypes,
  useNotifications,
} from '@shared/components/CommonNotifications'
import { getNode } from '@formkit/core'
import { ensureGraphqlId } from '@shared/graphql/utils'
import buildMentionSuggestion from './suggestions'
import type { FieldEditorProps, MentionUserItem } from '../types'
import { useMentionSuggestionsLazyQuery } from '../graphql/queries/mention/mentionSuggestions.api'

export const PLUGIN_NAME = 'mentionUser'
export const PLUGIN_LINK_NAME = 'mentionUserLink'
const ACTIVATOR = '@@'

export default (context: Ref<FormFieldContext<FieldEditorProps>>) => {
  const queryMentionsHandler = new QueryHandler(
    useMentionSuggestionsLazyQuery({
      query: '',
      group: '',
    }),
  )

  // TODO: possible race condition
  const getUserMentions = async (query: string, group: string) => {
    const result = await queryMentionsHandler.trigger({
      query,
      group: ensureGraphqlId('Group', group),
    })
    return result?.mentionSuggestions || []
  }

  return Mention.extend({
    name: PLUGIN_NAME,
    addCommands: () => ({
      openUserMention:
        () =>
        ({ chain }) =>
          chain().insertContent(` ${ACTIVATOR}`).run(),
    }),
  }).configure({
    suggestion: buildMentionSuggestion({
      activator: ACTIVATOR,
      type: 'user',
      insert(props: MentionUserItem) {
        const href = `${window.location.origin}/#user/profile/${props.internalId}`
        const text = props.fullname || props.email || ''
        return [
          {
            type: 'text',
            text,
            marks: [
              {
                type: PLUGIN_LINK_NAME,
                attrs: {
                  href,
                  'data-mention-user-id': props.internalId,
                },
              },
            ],
          },
        ]
      },
      async items({ query }) {
        if (!query) {
          return []
        }
        let { groupId: group } = context.value
        if (!group) {
          const { meta } = context.value
          const groupNodeId = meta?.[PLUGIN_NAME]?.groupNodeId
          if (groupNodeId) {
            const groupNode = getNode(groupNodeId)
            group = groupNode?.value as string
          }
        }
        if (!group) {
          const notifications = useNotifications()
          notifications.notify({
            id: 'mention-user-required-group',
            unique: true,
            message: __('Before you mention a user, please select a group.'),
            type: NotificationTypes.Warn,
          })
          return []
        }
        return getUserMentions(query, group)
      },
    }),
  })
}

export const UserLink = Link.extend({
  name: PLUGIN_LINK_NAME,
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
