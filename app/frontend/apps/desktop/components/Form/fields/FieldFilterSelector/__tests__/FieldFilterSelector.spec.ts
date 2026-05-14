// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { FormKit } from '@formkit/vue'

import { renderComponent } from '#tests/support/components/index.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import type { FilterAttribute } from '#shared/entities/object-attributes/types/store.ts'

import type { FilterSelectorEntityOverride } from '#desktop/components/Search/types.ts'

import type { FilterSelectorEntry } from '../types.ts'

const filterAttributes: FilterAttribute[] = [
  {
    name: 'ticket.title',
    label: 'Title',
    operators: ['matches'],
  },
  {
    name: 'ticket.number',
    label: '#',
    operators: ['matches'],
  },
]

const filterAttributesOverride = [
  {
    name: 'ticket.number',
    label: 'Ticket number',
    operators: ['matches'],
  },
]

const initialValue: FilterSelectorEntry[] = [
  {
    name: 'ticket.title',
    operator: 'matches',
    value: '',
  },
  {
    name: 'ticket.number',
    operator: 'matches',
    value: '',
  },
]

const renderFilterSelector = (
  value = initialValue,
  filterAttributesOverride: FilterSelectorEntityOverride[] | undefined = undefined,
) =>
  renderComponent(FormKit, {
    props: {
      id: 'filterSelector',
      type: 'filterSelector',
      name: 'filterSelector',
      formId: 'form',
      filterAttributes,
      filterAttributesOverride,
      addLabel: 'Add filter',
      value,
    },
    form: true,
    formField: true,
  })

describe('Fields - FieldFilterSelector', () => {
  it('debounces value updates before committing them to the FormKit node', async () => {
    vi.useFakeTimers()

    const view = renderFilterSelector()

    const titleInput = view.getByLabelText('Title')

    await view.events.type(titleInput, 'test')
    await waitForNextTick()

    expect(titleInput).toHaveValue('test')
    expect(getNode('filterSelector')?._value).toEqual(initialValue)

    vi.advanceTimersByTime(499)
    await waitForNextTick()

    expect(getNode('filterSelector')?._value).toEqual(initialValue)

    vi.advanceTimersByTime(1)
    await waitForNextTick()

    expect(getNode('filterSelector')?._value).toEqual([
      {
        name: 'ticket.title',
        operator: 'matches',
        value: 'test',
      },
      {
        name: 'ticket.number',
        operator: 'matches',
        value: '',
      },
    ])

    vi.useRealTimers()
  })

  it('applies filterAttributesOverride labels to rendered fields', async () => {
    const view = renderFilterSelector(initialValue, filterAttributesOverride)

    expect(view.getByLabelText('Ticket number')).toBeInTheDocument()
    expect(view.queryByLabelText('#')).not.toBeInTheDocument()
  })
})
