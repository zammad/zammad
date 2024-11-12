// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import renderComponent from '#tests/support/components/renderComponent.ts'

import ExternalReferenceLink from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarExternalReferences/ExternalReferenceLink.vue'

describe('IssueIntegrationContent', () => {
  it('renders link with id', () => {
    const wrapper = renderComponent(ExternalReferenceLink, {
      props: {
        id: 11,
        showId: true,
        title: 'Link Test',
        link: 'www.zammad.com',
        isEditable: true,
        tooltip: 'Zammad Test',
      },
      router: true,
    })

    expect(wrapper.getByRole('link')).toHaveTextContent('#11 Link Test')

    expect(wrapper.getByLabelText('Zammad Test')).toBeInTheDocument()
  })

  it('renders link without id', () => {
    const wrapper = renderComponent(ExternalReferenceLink, {
      props: {
        title: 'Link Test',
        id: 11,
        showId: false,
        link: 'www.zammad.com',
        isEditable: true,
        tooltip: 'Zammad Test',
      },
      router: true,
    })

    expect(wrapper.getByRole('link')).toHaveTextContent('Link Test')
  })

  it('hides remove button if not editable', () => {
    const wrapper = renderComponent(ExternalReferenceLink, {
      props: {
        title: 'Link Test',
        id: 11,
        showId: false,
        link: 'www.zammad.com',
        isEditable: false,
        tooltip: 'Remove Zammad Test',
      },
      router: true,
    })

    expect(
      wrapper.queryByRole('button', { name: 'Remove Zammad Test' }),
    ).not.toBeInTheDocument()
  })

  it('emits remove event', () => {
    const wrapper = renderComponent(ExternalReferenceLink, {
      props: {
        title: 'Link Test',
        id: 11,
        showId: false,
        link: 'www.zammad.com',
        isEditable: true,
        tooltip: 'Remove Zammad Test',
      },
      router: true,
    })

    wrapper.getByRole('button', { name: 'Remove Zammad Test' }).click()

    expect(wrapper.emitted('remove')).toBeTruthy()

    expect(wrapper.emitted('remove')).toEqual([[{ id: 11 }]])
  })
})
