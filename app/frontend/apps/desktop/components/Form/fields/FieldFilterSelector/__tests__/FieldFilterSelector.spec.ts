// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { FormKit } from '@formkit/vue'

import { renderComponent } from '#tests/support/components/index.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import type { ObjectSelectOption } from '#shared/entities/object-attributes/form/resolver/fields/select.ts'
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
  {
    name: 'ticket.subject',
    label: 'Subject',
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

interface RenderOptions {
  filterAttributesOverride?: FilterSelectorEntityOverride[]
  filterAttributes?: FilterAttribute[]
  filterAttributeOptions?: Record<string, ObjectSelectOption[]>
}

const renderFilterSelector = (value = initialValue, options: RenderOptions = {}) =>
  renderComponent(FormKit, {
    props: {
      id: 'filterSelector',
      type: 'filterSelector',
      name: 'filterSelector',
      formId: 'form',
      filterAttributes: options.filterAttributes ?? filterAttributes,
      filterAttributesOverride: options.filterAttributesOverride,
      filterAttributeOptions: options.filterAttributeOptions,
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
    const view = renderFilterSelector(initialValue, { filterAttributesOverride })

    expect(view.getByLabelText('Ticket number')).toBeInTheDocument()
    expect(view.queryByLabelText('#')).not.toBeInTheDocument()
  })

  it('keeps trailing rows intact when a middle row is removed', async () => {
    vi.useFakeTimers()

    const view = renderFilterSelector([
      { name: 'ticket.title', operator: 'matches', value: 'Alpha' },
      { name: 'ticket.number', operator: 'matches', value: 'Beta' },
      { name: 'ticket.subject', operator: 'matches', value: 'Gamma' },
    ])

    expect(view.getByLabelText('Title')).toHaveValue('Alpha')
    expect(view.getByLabelText('#')).toHaveValue('Beta')
    expect(view.getByLabelText('Subject')).toHaveValue('Gamma')

    const removeButtons = view.getAllByRole('button', { name: 'Remove attribute' })
    // The middle row (#) — the bug we're guarding against is that removing
    // a non-last row would clobber the values in rows below it.
    await view.events.click(removeButtons[1])
    await waitForNextTick()

    expect(view.queryByLabelText('#')).not.toBeInTheDocument()
    expect(view.getByLabelText('Title')).toHaveValue('Alpha')
    expect(view.getByLabelText('Subject')).toHaveValue('Gamma')

    // Flush the value-commit debounce and inspect the underlying FormKit
    // node — both surviving rows must keep their stored values.
    vi.advanceTimersByTime(500)
    await waitForNextTick()

    expect(getNode('filterSelector')?._value).toEqual([
      { name: 'ticket.title', operator: 'matches', value: 'Alpha' },
      { name: 'ticket.subject', operator: 'matches', value: 'Gamma' },
    ])

    vi.useRealTimers()
  })

  it('hides the "Add filter" button when no available attribute has a supported operator', async () => {
    // Only attribute is a User-relation that uses autocomplete; `is` returns
    // null for autocompleteFilterType so the dropdown has nothing to offer.
    const view = renderFilterSelector([], {
      filterAttributes: [
        {
          name: 'ticket.owner_id',
          label: 'Owner',
          operators: ['is'],
          autocompleteFilterType: 'customer',
        },
      ],
    })

    expect(view.queryByRole('button', { name: 'Add filter' })).not.toBeInTheDocument()
  })

  it('applies filterAttributeOptions to rendered relation sub-fields', async () => {
    const relationAttributes: FilterAttribute[] = [
      {
        name: 'ticket.group_id',
        label: 'Group',
        operators: ['is'],
      },
    ]

    const view = renderFilterSelector([{ name: 'ticket.group_id', operator: 'is', value: null }], {
      filterAttributes: relationAttributes,
      filterAttributeOptions: {
        'ticket.group_id': [
          { value: 1, label: 'Users' },
          { value: 2, label: 'Sales' },
        ],
      },
    })

    await view.events.click(view.getByLabelText('Group'))

    expect(await view.findByRole('option', { name: 'Users' })).toBeInTheDocument()
    expect(view.getByRole('option', { name: 'Sales' })).toBeInTheDocument()
  })
})
