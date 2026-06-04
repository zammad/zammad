// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { waitFor } from '@testing-library/vue'

import renderComponent from '#tests/support/components/renderComponent.ts'

import type { FilterAttribute } from '#shared/entities/object-attributes/types/store.ts'

import SearchEntityFiltersForm from '../SearchControls/SearchEntityFiltersForm.vue'

// A compound (`in range`) attribute — its label renders in the fieldset's
// legend, the path the config-driven accounted-time unit actually uses.
const filterAttributes: FilterAttribute[] = [
  { name: 'ticket.foo', label: 'Foo', operators: ['in range'] },
]

const renderForm = (filterAttributesOverride: unknown) =>
  renderComponent(SearchEntityFiltersForm, {
    props: {
      entity: 'Ticket',
      filters: [{ name: 'ticket.foo', operator: 'in range', value: [1, 2] }],
      filterAttributes,
      filterAttributesOverride,
    },
    form: true,
  })

describe('SearchEntityFiltersForm - filterAttributesOverride', () => {
  it('renders the overridden legend with its placeholder and re-renders when the override changes', async () => {
    const view = renderForm([
      { name: 'ticket.foo', label: 'Bar - %s', labelPlaceholder: ['minute(s)'] },
    ])

    expect(await view.findByText('Bar - minute(s)')).toBeInTheDocument()

    // The override is config-driven and arrives via a (resolved) prop. Form
    // resolves the schema once, so this only stays live because it's passed as
    // a ref — verify a changed override reaches the already-rendered field.
    await view.rerender({
      filterAttributesOverride: [
        { name: 'ticket.foo', label: 'Bar - %s', labelPlaceholder: ['hour(s)'] },
      ],
    })

    await waitFor(() => expect(view.getByText('Bar - hour(s)')).toBeInTheDocument())
    expect(view.queryByText('Bar - minute(s)')).not.toBeInTheDocument()
  })
})
