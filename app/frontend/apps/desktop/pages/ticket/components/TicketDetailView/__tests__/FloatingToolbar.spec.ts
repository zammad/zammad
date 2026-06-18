// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import { createDummyTicket } from '#shared/entities/ticket-article/__tests__/mocks/ticket.ts'
import type { AppSpecificTicketArticleType } from '#shared/entities/ticket-article/action/plugins/types.ts'

import FloatingToolbar, { type Props } from '../FloatingToolbar.vue'

const agentTicketArticleTypes: AppSpecificTicketArticleType[] = [
  {
    value: 'note',
    label: 'Note',
    buttonLabel: 'Add internal note',
    icon: 'pencil-square',
    internal: true,
    view: { agent: ['change'] },
    fields: {},
  },
]

const customerTicketArticleTypes: AppSpecificTicketArticleType[] = [
  {
    value: 'web',
    label: 'Web',
    buttonLabel: 'Add reply',
    icon: 'web',
    internal: false,
    view: {},
    fields: {},
  },
]

const customerTicket = () =>
  createDummyTicket({ defaultPolicy: { update: true, agentReadAccess: false } })

const renderToolbar = (props: Partial<Props> = {}) =>
  renderComponent(FloatingToolbar, {
    props: {
      unreadArticleCount: 3,
      isReachingBottom: false,
      ticket: createDummyTicket(),
      ticketArticleTypes: agentTicketArticleTypes,
      newArticlePresent: false,
      ...props,
    },
  })

describe('FloatingToolbar', () => {
  describe('agent user', () => {
    beforeEach(() => {
      mockPermissions(['ticket.agent'])
    })

    it('renders all toolbar controls by default', () => {
      const wrapper = renderToolbar()

      expect(wrapper.getByRole('toolbar')).toBeVisible()
      expect(wrapper.getByRole('button', { name: 'Add internal note' })).toBeVisible()
      expect(wrapper.getByIconName('pencil-square')).toBeVisible()

      expect(wrapper.getByRole('button', { name: 'Scroll to start' })).toBeVisible()
      expect(wrapper.getByRole('button', { name: 'Scroll to unread article' })).toBeVisible()
      expect(wrapper.getByRole('status', { name: 'Unread messages count' })).toHaveTextContent('3')
    })

    it('hides scroll to bottom and article action when reaching the bottom', () => {
      const wrapper = renderToolbar({ isReachingBottom: true })

      expect(wrapper.queryByRole('button', { name: 'Add internal note' })).not.toBeInTheDocument()
      expect(wrapper.queryByRole('button', { name: 'Scroll to start' })).toBeVisible()
      expect(wrapper.queryByRole('button', { name: 'Scroll to end' })).not.toBeInTheDocument()
      expect(
        wrapper.queryByRole('button', { name: 'Scroll to unread article' }),
      ).not.toBeInTheDocument()
      expect(
        wrapper.queryByRole('status', { name: 'Unread messages count' }),
      ).not.toBeInTheDocument()
    })

    it('hides the scroll to top action when reaching the top', () => {
      const wrapper = renderToolbar({ isReachingTop: true })

      expect(wrapper.queryByRole('button', { name: 'Scroll to start' })).not.toBeInTheDocument()
      expect(wrapper.getByRole('button', { name: 'Add internal note' })).toBeVisible()
      expect(wrapper.getByRole('button', { name: 'Scroll to unread article' })).toBeVisible()
    })

    it('truncates the unread count display when it exceeds 9', () => {
      const wrapper = renderToolbar({ unreadArticleCount: 10 })

      expect(wrapper.getByRole('status', { name: 'Unread messages count' })).toHaveTextContent('9+')
    })

    it('hides the reply action when a new article is present', () => {
      const wrapper = renderToolbar({ newArticlePresent: true })

      expect(wrapper.queryByRole('button', { name: 'Add internal note' })).not.toBeInTheDocument()
      expect(wrapper.getByRole('button', { name: 'Scroll to unread article' })).toBeVisible()
      expect(wrapper.getByRole('status', { name: 'Unread messages count' })).toHaveTextContent('3')
    })

    it('emits show-article-form with the article type when the note button is clicked', async () => {
      const wrapper = renderToolbar()

      await wrapper.events.click(wrapper.getByRole('button', { name: 'Add internal note' }))

      expect(wrapper.emitted('show-article-form')).toEqual([['note', expect.any(Function)]])
    })

    it('emits scroll-to-start when the scroll up button is clicked', async () => {
      const wrapper = renderToolbar()

      await wrapper.events.click(wrapper.getByRole('button', { name: 'Scroll to start' }))

      expect(wrapper.emitted('scroll-to-start')).toHaveLength(1)
    })

    it('emits scroll-to-unread-article when the scroll down button is clicked and unread articles exist', async () => {
      const wrapper = renderToolbar()

      await wrapper.events.click(wrapper.getByRole('button', { name: 'Scroll to unread article' }))

      expect(wrapper.emitted('scroll-to-unread-article')).toHaveLength(1)
    })

    it('emits scroll-to-end when the scroll down button is clicked and unread articles do not exist', async () => {
      const wrapper = renderToolbar({ unreadArticleCount: 0 })

      await wrapper.events.click(wrapper.getByRole('button', { name: 'Scroll to end' }))

      expect(wrapper.emitted('scroll-to-end')).toHaveLength(1)
    })
  })

  describe('customer user', () => {
    beforeEach(() => {
      mockPermissions(['ticket.customer'])
    })

    it('renders all toolbar controls by default', () => {
      const wrapper = renderToolbar({
        ticket: customerTicket(),
        ticketArticleTypes: customerTicketArticleTypes,
      })

      expect(wrapper.getByRole('toolbar')).toBeVisible()
      expect(wrapper.getByRole('button', { name: 'Add reply' })).toBeVisible()
      expect(wrapper.getByIconName('chat-right-text')).toBeVisible() // Icon alias for `web`

      expect(wrapper.getByRole('button', { name: 'Scroll to start' })).toBeVisible()
      expect(wrapper.getByRole('button', { name: 'Scroll to unread article' })).toBeVisible()
      expect(wrapper.getByRole('status', { name: 'Unread messages count' })).toHaveTextContent('3')
    })

    it('emits show-article-form with the article type when the reply button is clicked', async () => {
      const wrapper = renderToolbar({
        ticket: customerTicket(),
        ticketArticleTypes: customerTicketArticleTypes,
      })

      await wrapper.events.click(wrapper.getByRole('button', { name: 'Add reply' }))

      expect(wrapper.emitted('show-article-form')).toEqual([['web', expect.any(Function)]])
    })

    it('hides the toolbar when no condition applies', () => {
      const wrapper = renderToolbar({
        isReachingBottom: true,
        isReachingTop: true,
        newArticlePresent: false,
        unreadArticleCount: 0,
      })

      expect(wrapper.queryByRole('toolbar')).not.toBeInTheDocument()
    })
  })
})
