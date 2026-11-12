// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { markRaw } from 'vue'

import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { useChatWindowsStore } from '#desktop/entities/chat/stores/chatWindows.ts'

import ChatNavigationItem from './components/ChatNavigationItem.vue'

import type { RouteRecordRaw } from 'vue-router'

const ChatView = () => import('./views/Chat.vue')

const route: RouteRecordRaw[] = [
  {
    path: '/chat',
    // The address of the old UI, which a link from there or the switch to this view brings along.
    alias: '/customer_chat',
    name: 'Chat',
    component: ChatView,
    meta: {
      title: __('Chat'),
      requiresAuth: true,
      requiredPermission: ['chat.agent'],
      icon: 'chat',
      mainNavigation: true,
      // Before the caller log, as in the old navigation.
      order: 350,
      // The entry carries the waiting count and the availability switch, and
      //   hides itself while the chat feature is off; the page stays reachable.
      navigationItemComponent: markRaw(ChatNavigationItem),
      pageKey: 'chat',
      permanentItem: true,
    },
  },
  // The session link of the old UI, which the search results carry: the session opens as a window
  //   of the chat page, and the address bar shows the page, behind which the page the agent came
  //   from stays. The window list keeps the session, so the view is never rendered for this route.
  {
    path: '/chat/session/:internalId(\\d+)',
    alias: '/customer_chat/session/:internalId(\\d+)',
    name: 'ChatSession',
    component: ChatView,
    beforeEnter: (to) => {
      const store = useChatWindowsStore()
      const id = convertToGraphQLId('Chat::Session', String(to.params.internalId))

      store.openWindow(id)
      store.windowToReveal = id

      return { name: 'Chat' }
    },
    meta: {
      title: __('Chat'),
      requiresAuth: true,
      requiredPermission: ['chat.agent'],
    },
  },
]

export default route
