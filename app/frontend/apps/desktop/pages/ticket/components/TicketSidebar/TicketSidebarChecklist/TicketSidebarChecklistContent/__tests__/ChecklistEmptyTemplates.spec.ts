// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import ChecklistEmptyTemplates from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarChecklist/TicketSidebarChecklistContent/ChecklistEmptyTemplates.vue'

const renderChecklistContent = () => {
  return renderComponent(ChecklistEmptyTemplates, {
    router: true,
  })
}

describe('ChecklistEmptyTemplates', () => {
  it('shows template information for an agent', () => {
    mockPermissions(['ticket.agent'])

    const wrapper = renderChecklistContent()

    expect(
      wrapper.getByText('No checklist templates have been created yet.'),
    ).toBeInTheDocument()

    expect(
      wrapper.getByText(
        'With checklist templates you can pre-fill your checklists.',
      ),
    ).toBeInTheDocument()
  })

  it('shows the link to the admin interface for an admin', () => {
    mockPermissions(['admin'])

    const wrapper = renderChecklistContent()

    expect(
      wrapper.getByRole('link', {
        name: 'Create a new checklist template in the admin interface.',
      }),
    ).toBeInTheDocument()
  })

  it('hides the link to the admin interface for an agent', () => {
    mockPermissions(['ticket.agent'])

    const wrapper = renderChecklistContent()

    expect(
      wrapper.queryByRole('link', {
        name: 'Create a new checklist template in the admin interface.',
      }),
    ).not.toBeInTheDocument()
  })
})
