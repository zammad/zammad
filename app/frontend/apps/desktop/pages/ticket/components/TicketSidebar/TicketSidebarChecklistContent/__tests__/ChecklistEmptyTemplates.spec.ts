// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import ChecklistEmptyTemplates from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarChecklistContent/ChecklistEmptyTemplates.vue'

const renderChecklistContent = () => {
  return renderComponent(ChecklistEmptyTemplates, {
    router: true,
  })
}

describe('ChecklistEmptyTemplates', () => {
  it('shows content for an admin', () => {
    mockPermissions(['admin'])

    const wrapper = renderChecklistContent()

    expect(
      wrapper.getByText('No checklist templates have been created yet.'),
    ).toBeInTheDocument()

    expect(
      wrapper.getByText(
        'With checklist templates you can pre-fill your checklists.',
      ),
    ).toBeInTheDocument()
    expect(
      wrapper.getByRole('link', {
        name: 'Create a new checklist template in the admin interface.',
      }),
    ).toBeInTheDocument()
  })

  it('hides content for an agent', () => {
    mockPermissions(['agent'])

    const wrapper = renderChecklistContent()

    expect(
      wrapper.queryByText('No checklist templates have been created yet.'),
    ).not.toBeInTheDocument()

    expect(
      wrapper.queryByText(
        'With checklist templates you can pre-fill your checklists.',
      ),
    ).not.toBeInTheDocument()

    expect(
      wrapper.queryByRole('link', {
        name: 'Create a new checklist template in the admin interface.',
      }),
    ).not.toBeInTheDocument()
  })
})
