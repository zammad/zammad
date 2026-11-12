// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import renderComponent from '#tests/support/components/renderComponent.ts'

import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import ChatSession from '../ChatSession.vue'

const chatSession = (internalId: number, name: string | null) => ({
  __typename: 'ChatSession' as const,
  id: convertToGraphQLId('Chat::Session', internalId),
  internalId,
  name,
})

const renderSession = (item: ReturnType<typeof chatSession>) =>
  renderComponent(ChatSession, {
    props: {
      item,
      mode: 'quick-search-result',
    },
    router: true,
    routerRoutes: [
      { path: '/', name: 'Dashboard', component: { template: '<div />' } },
      {
        path: '/chat/session/:internalId(\\d+)',
        name: 'ChatSession',
        component: { template: '<div />' },
      },
    ],
  })

describe('ChatSession quicksearch item', () => {
  // The row of the old UI: the number, and the name an agent gave the session, when there is one.
  it('renders the number and the name of the session', () => {
    const wrapper = renderSession(chatSession(12, 'VPN setup'))

    expect(wrapper.getByText('#12 VPN setup')).toBeInTheDocument()
    expect(wrapper.getByIconName('chat')).toBeInTheDocument()
  })

  it('renders the number alone without a name', () => {
    const wrapper = renderSession(chatSession(12, null))

    expect(wrapper.getByText('#12')).toBeInTheDocument()
  })

  it('links to the session on the chat page', () => {
    const wrapper = renderSession(chatSession(12, 'VPN setup'))

    expect(wrapper.getByRole('link', { name: '#12 VPN setup' })).toHaveAttribute(
      'href',
      '/desktop/chat/session/12',
    )
  })
})
