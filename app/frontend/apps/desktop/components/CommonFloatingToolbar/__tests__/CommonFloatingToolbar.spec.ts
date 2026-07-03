// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import CommonFloatingToolbar, { type Props } from '../CommonFloatingToolbar.vue'

const renderToolbar = (props: Partial<Props> = {}) =>
  renderComponent(CommonFloatingToolbar, {
    props: {
      label: 'Toolbar actions',
      isReachingBottom: false,
      ...props,
    },
    slots: {
      'primary-action': '<button>Primary action</button>',
    },
  })

describe('CommonFloatingToolbar', () => {
  it('renders all toolbar controls by default', () => {
    const wrapper = renderToolbar()

    expect(wrapper.getByRole('toolbar', { name: 'Toolbar actions' })).toBeVisible()
    expect(wrapper.getByRole('button', { name: 'Primary action' })).toBeVisible()
    expect(wrapper.getByRole('button', { name: 'Scroll to start' })).toBeVisible()
    expect(wrapper.getByRole('button', { name: 'Scroll to end' })).toBeVisible()
  })

  it('hides the primary action when hide-primary-action is set', () => {
    const wrapper = renderToolbar({ hidePrimaryAction: true })

    expect(wrapper.queryByRole('button', { name: 'Primary action' })).not.toBeInTheDocument()
  })

  it('does not render a primary action section when no slot content is given', () => {
    const wrapper = renderComponent(CommonFloatingToolbar, {
      props: {
        label: 'Toolbar actions',
        isReachingBottom: false,
      },
    })

    expect(wrapper.queryByRole('button', { name: 'Primary action' })).not.toBeInTheDocument()
  })

  it('hides the scroll to start action when reaching the top', () => {
    const wrapper = renderToolbar({ isReachingTop: true })

    expect(wrapper.queryByRole('button', { name: 'Scroll to start' })).not.toBeInTheDocument()
    expect(wrapper.getByRole('button', { name: 'Scroll to end' })).toBeVisible()
  })

  it('hides the scroll to end action when reaching the bottom', () => {
    const wrapper = renderToolbar({ isReachingBottom: true })

    expect(wrapper.queryByRole('button', { name: 'Scroll to end' })).not.toBeInTheDocument()
    expect(wrapper.getByRole('button', { name: 'Scroll to start' })).toBeVisible()
  })

  it('hides the toolbar entirely once both ends are reached and nothing is unread', () => {
    const wrapper = renderToolbar({ isReachingBottom: true, isReachingTop: true })

    expect(wrapper.queryByRole('toolbar')).not.toBeInTheDocument()
  })

  it('shows an unread count badge and tooltip on the scroll to end action', () => {
    const wrapper = renderToolbar({ unreadCount: 3, unreadTooltip: 'Scroll to unread item' })

    expect(wrapper.getByRole('status', { name: 'Unread messages count' })).toHaveTextContent('3')
    expect(wrapper.queryByRole('button', { name: 'Scroll to end' })).not.toBeInTheDocument()
  })

  it('truncates the unread count display when it exceeds 9', () => {
    const wrapper = renderToolbar({ unreadCount: 10 })

    expect(wrapper.getByRole('status', { name: 'Unread messages count' })).toHaveTextContent('9+')
  })

  it('keeps the toolbar visible while unread items exist even at both ends', () => {
    const wrapper = renderToolbar({ isReachingBottom: true, isReachingTop: true, unreadCount: 1 })

    expect(wrapper.getByRole('toolbar')).toBeVisible()
  })

  it('emits scroll-to-start when the scroll up button is clicked', async () => {
    const wrapper = renderToolbar()

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Scroll to start' }))

    expect(wrapper.emitted('scroll-to-start')).toHaveLength(1)
  })

  it('emits scroll-to-end when the scroll down button is clicked and nothing is unread', async () => {
    const wrapper = renderToolbar()

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Scroll to end' }))

    expect(wrapper.emitted('scroll-to-end')).toHaveLength(1)
  })

  it('emits scroll-to-unread when the scroll down button is clicked and items are unread', async () => {
    const wrapper = renderToolbar({ unreadCount: 2 })

    await wrapper.events.click(wrapper.getByRole('button', { name: 'Scroll to unread item' }))

    expect(wrapper.emitted('scroll-to-unread')).toHaveLength(1)
  })
})
