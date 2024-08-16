// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { waitFor } from '@testing-library/vue'

import renderComponent from '#tests/support/components/renderComponent.ts'

import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import ChecklistTemplates from '#desktop/pages/ticket/components/TicketSidebar/TicketSidebarChecklist/TicketSidebarChecklistContent/ChecklistTemplates.vue'

const templates = [
  { label: 'Test', key: convertToGraphQLId('Checklist', 1) },
  { label: 'Test Template', key: convertToGraphQLId('Checklist', 2) },
  { label: 'Starship Template', key: convertToGraphQLId('Checklist', 3) },
]

const templateNames = templates.map((template) => template.label)

describe('CheckListTemplates', () => {
  it('shows a list of templates', async () => {
    const wrapper = renderComponent(ChecklistTemplates, {
      props: {
        templates,
      },
    })

    expect(
      wrapper.getByText('Or choose a checklist template.'),
    ).toBeInTheDocument()
    expect(wrapper.getByText('Add From a Template')).toBeInTheDocument()

    await wrapper.events.click(wrapper.getByText('Add From a Template'))

    await waitFor(() => expect(wrapper.getByRole('menu')).toBeInTheDocument())

    while (templateNames.length) {
      const templateName = templateNames.shift()
      expect(wrapper.getByText(templateName as string)).toBeInTheDocument()
    }
  })
})
