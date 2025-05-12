// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import renderComponent from '#tests/support/components/renderComponent.ts'

import IssueTrackerLinkFlyout from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarExternalReferences/TicketSidebarExternalIssueTracker/IssueTrackerLinkFlyout.vue'

describe('IssueTrackerLinkFlyout', () => {
  it('shows error if user does not provide a link', async () => {
    const mockFn = vi.fn()

    const wrapper = renderComponent(IssueTrackerLinkFlyout, {
      props: {
        name: 'gitlab',
        icon: 'gitlab',
        label: 'Flyout Link',
        issueLinks: [],
        inputPlaceholder: 'Enter a link',
        onSubmit: (link: string) => mockFn(link),
      },
      form: true,
      flyout: true,
      router: true,
    })

    await wrapper.events.type(
      wrapper.getByPlaceholderText('Enter a link'),
      'totally wrong',
    )

    await wrapper.events.click(
      wrapper.getByRole('button', { name: 'Link Issue' }),
    )

    expect(
      await wrapper.findByText('Please include a valid url.'),
    ).toBeInTheDocument()

    expect(mockFn).not.toHaveBeenCalled()

    await wrapper.events.clear(wrapper.getByPlaceholderText('Enter a link'))

    await wrapper.events.click(
      wrapper.getByRole('button', { name: 'Link Issue' }),
    )

    expect(
      await wrapper.findByText('This field is required.'),
    ).toBeInTheDocument()

    expect(mockFn).not.toHaveBeenCalled()
  })

  it('shows error if user tries to submit a link that already exists', async () => {
    const mockFn = vi.fn()

    const wrapper = renderComponent(IssueTrackerLinkFlyout, {
      props: {
        name: 'gitlab',
        icon: 'gitlab',
        label: 'Flyout Link',
        issueLinks: ['https://gitlab.com/issue/111'],
        inputPlaceholder: 'Enter a link',
        onSubmit: (link: string) => mockFn(link),
      },
      form: true,
      flyout: true,
    })

    await wrapper.events.type(
      wrapper.getByPlaceholderText('Enter a link'),
      'https://gitlab.com/issue/111',
    )

    await wrapper.events.click(
      wrapper.getByRole('button', { name: 'Link Issue' }),
    )

    expect(
      await wrapper.findByText('The issue reference already exists.'),
    ).toBeInTheDocument()
  })
})
