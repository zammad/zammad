// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { getNode } from '@formkit/core'
import { FormKit } from '@formkit/vue'
import { waitFor } from '@testing-library/vue'

import { renderComponent } from '#tests/support/components/index.ts'
import { waitForNextTick } from '#tests/support/utils.ts'

import type { ObjectSelectOption } from '#shared/entities/object-attributes/form/resolver/fields/select.ts'
import type { FilterAttribute } from '#shared/entities/object-attributes/types/store.ts'
import { mockAutocompleteSearchTagQuery } from '#shared/entities/tags/graphql/queries/autocompleteTags.mocks.ts'
import { i18n } from '#shared/i18n.ts'

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

    vi.advanceTimersByTime(449)
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

    const removeButtons = view.getAllByRole('button', { name: 'Remove filter' })
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
    const view = renderFilterSelector([], {
      filterAttributes: [
        {
          name: 'ticket.title',
          label: 'Title',
          operators: ['unknown_operator'],
        },
      ],
    })

    expect(view.queryByRole('button', { name: 'Add filter' })).not.toBeInTheDocument()
  })

  it('offers autocomplete-relation attributes (e.g. customer/agent) via the is operator', async () => {
    const view = renderFilterSelector([], {
      filterAttributes: [
        {
          name: 'ticket.owner_id',
          label: 'Owner',
          operators: ['is'],
          autocompleteFilterType: 'agent',
        },
      ],
    })

    expect(view.getByRole('button', { name: 'Add filter' })).toBeInTheDocument()
  })

  it('mounts the agent autocomplete row for an autocomplete-typed attribute', async () => {
    // End-to-end render of the `is.ts` → schema-node → FormKit pipeline:
    // when the row's attribute carries `autocompleteFilterType: 'agent'`,
    // the schema fragment must resolve to a FormKit `agent` field and the
    // labelled input must appear in the DOM. Catches regressions in the
    // operator-to-schema conversion that the per-layer unit tests can't see.
    const view = renderFilterSelector([{ name: 'ticket.owner_id', operator: 'is', value: null }], {
      filterAttributes: [
        {
          name: 'ticket.owner_id',
          label: 'Owner',
          operators: ['is'],
          autocompleteFilterType: 'agent',
        },
      ],
    })

    expect(view.getByLabelText('Owner')).toBeInTheDocument()
  })

  it('mounts the tags autocomplete row with canCreate disabled', async () => {
    // Same end-to-end guard as the agent case, plus a check that the filter
    // resolver's `canCreate: false` flag survives the operator-props merge in
    // FieldFilterSelectorInput and reaches the rendered tags field. Tags use
    // the `contains one` operator (matches the existing ES + SQL selector
    // wiring), unlike the other relation autocompletes which use `is`.

    // FieldTagsWrapper sets defaultFilter: '*' on mount, which immediately
    // triggers an Apollo query — mock it so the test doesn't leave an
    // unhandled rejection behind.
    mockAutocompleteSearchTagQuery({ autocompleteSearchTag: [] })

    const view = renderFilterSelector(
      [{ name: 'ticket.tags', operator: 'contains one', value: [] }],
      {
        filterAttributes: [
          {
            name: 'ticket.tags',
            label: 'Tags',
            operators: ['contains one'],
            autocompleteFilterType: 'tags',
            operatorFilterProps: { 'contains one': { canCreate: false } },
          },
        ],
      },
    )

    expect(view.getByLabelText('Tags')).toBeInTheDocument()
    expect(getNode('filterSelector-ticket.tags-value')?.props.canCreate).toBe(false)
  })

  const rangeAttribute = {
    name: 'ticket.escalation_count',
    label: 'Escalation count',
    operators: ['in range'],
  }

  it('renders the `in range` operator as two number inputs and stores a [min, max] array', async () => {
    // End-to-end render of the compound operator: the two number inputs mount
    // with the row's initial bounds and FormKit's list aggregates them, so the
    // row value stays a `[min, max]` array.
    const view = renderFilterSelector(
      [{ name: 'ticket.escalation_count', operator: 'in range', value: [10, 20] }],
      { filterAttributes: [rangeAttribute] },
    )

    const inputs = view.getAllByRole('spinbutton')
    expect(inputs).toHaveLength(2)
    expect(inputs[0]).toHaveValue(10)
    expect(inputs[1]).toHaveValue(20)

    // The compound field is exposed as a group named by the attribute label,
    // and each input carries its own (visually-hidden) label matching its
    // placeholder — so every bound is individually announced with context.
    expect(view.getByRole('group', { name: 'Escalation count' })).toBeInTheDocument()
    expect(view.getByLabelText('min')).toBe(inputs[0])
    expect(view.getByLabelText('max')).toBe(inputs[1])

    // The `-` separator renders between the two inputs but is not a value
    // input, so the row value stays a `[min, max]` array.
    expect(view.getByText('-')).toBeInTheDocument()

    expect(getNode('filterSelector')?._value).toEqual([
      { name: 'ticket.escalation_count', operator: 'in range', value: [10, 20] },
    ])
  })

  it('focuses the first bound when the legend is clicked (like a label)', async () => {
    const view = renderFilterSelector(
      [{ name: 'ticket.escalation_count', operator: 'in range', value: [10, 20] }],
      { filterAttributes: [rangeAttribute] },
    )

    const inputs = view.getAllByRole('spinbutton')
    expect(inputs[0]).not.toHaveFocus()

    await view.events.click(
      view.getByRole('group', { name: 'Escalation count' }).querySelector('legend')!,
    )

    // `focusFieldInput` focuses on the next frame, so wait for it.
    await waitFor(() => expect(inputs[0]).toHaveFocus())
  })

  it('re-translates the legend reactively when the translation map changes', async () => {
    const view = renderFilterSelector(
      [{ name: 'ticket.escalation_count', operator: 'in range', value: [10, 20] }],
      { filterAttributes: [rangeAttribute] },
    )

    expect(view.getByText('Escalation count')).toBeInTheDocument()

    try {
      // No schema rebuild here — the legend re-translates purely because its
      // `$legendLabel` expression is reactive (like a FormKit field label).
      i18n.setTranslationMap(new Map([['Escalation count', 'Eskalationszähler']]))
      await waitForNextTick()

      expect(view.getByText('Eskalationszähler')).toBeInTheDocument()
    } finally {
      i18n.setTranslationMap(new Map())
    }
  })

  it('reflects an external `in range` value update into the inputs (deep-link / taskbar restore)', async () => {
    // Regression: an external value replacement (e.g. the route → state re-sync
    // on a search-term change) must reach the compound row, not be ignored and
    // then clobbered by the container re-committing its stale value.
    const view = renderFilterSelector(
      [{ name: 'ticket.escalation_count', operator: 'in range', value: [10, 20] }],
      { filterAttributes: [rangeAttribute] },
    )

    // An external restore replaces the whole filter value on the node (this is
    // what `setEntityFilters` does on a route → state re-sync).
    getNode('filterSelector')?.input([
      { name: 'ticket.escalation_count', operator: 'in range', value: [99, 88] },
    ])
    await waitForNextTick()

    const inputs = view.getAllByRole('spinbutton')
    expect(inputs[0]).toHaveValue(99)
    expect(inputs[1]).toHaveValue(88)
    expect(getNode('filterSelector')?._value).toEqual([
      { name: 'ticket.escalation_count', operator: 'in range', value: [99, 88] },
    ])
  })

  it('seeds both `in range` slots so the value is always a length-2 array', async () => {
    // The backend selector requires exactly two elements. Both number inputs
    // seed their `value.0`/`value.1` slot on mount, so even an untouched range
    // is a length-2 array (`['', '']`) rather than collapsing to one element —
    // a min-only filter is then `['30', '']`, never `['30']`. The all-blank
    // case is dropped upstream (see the useSearchAdvancedFilters spec) before
    // it reaches the backend.
    const view = renderFilterSelector(
      [{ name: 'ticket.escalation_count', operator: 'in range', value: undefined }],
      {
        filterAttributes: [
          { name: 'ticket.escalation_count', label: 'Escalation count', operators: ['in range'] },
        ],
      },
    )

    expect(view.getAllByRole('spinbutton')).toHaveLength(2)

    const rows = getNode('filterSelector')?._value as Array<{ value: unknown }>
    expect(Array.isArray(rows?.[0]?.value)).toBe(true)
    expect(rows?.[0]?.value).toHaveLength(2)
  })

  const relativeAttribute: FilterAttribute = {
    name: 'ticket.created_at',
    label: 'Created at',
    operators: ['within last (relative)'],
    attributeFieldType: 'datetime',
  }

  it('renders `within last (relative)` as a value + unit grouped under the attribute label', async () => {
    // The two inputs bind to *separate* row keys (`value` and `range`)
    // yet share one fieldset/legend — unlike `in range`, which
    // aggregates its inputs into a single array value.
    const view = renderFilterSelector(
      [{ name: 'ticket.created_at', operator: 'within last (relative)', value: 5, range: 'day' }],
      { filterAttributes: [relativeAttribute] },
    )

    expect(view.getByRole('group', { name: 'Created at' })).toBeInTheDocument()

    expect(view.getByLabelText('Value')).toHaveValue(5)
    expect(view.getByLabelText('Unit')).toBeInTheDocument()

    expect(getNode('filterSelector-ticket.created_at-value')?._value).toBe(5)
    expect(getNode('filterSelector-ticket.created_at-range')?._value).toBe('day')

    expect(getNode('filterSelector')?._value).toEqual([
      { name: 'ticket.created_at', operator: 'within last (relative)', value: 5, range: 'day' },
    ])
  })

  const dateAttribute: FilterAttribute = {
    name: 'ticket.created_at',
    label: 'Created at',
    operators: ['in range', 'within last (relative)'],
    attributeFieldType: 'datetime',
  }

  it('labels a multi-operator `within last (relative)` row as "Field - Operator"', async () => {
    const view = renderFilterSelector(
      [{ name: 'ticket.created_at', operator: 'within last (relative)', value: 5, range: 'day' }],
      { filterAttributes: [dateAttribute] },
    )

    expect(
      view.getByRole('group', { name: 'Created at - within last (relative)' }),
    ).toBeInTheDocument()
  })

  it('labels a multi-operator `in range` row as "Field - Operator"', async () => {
    // A single native date-range field is routed through the fieldset/legend so
    // it, too, spells out the operator.
    const view = renderFilterSelector(
      [{ name: 'ticket.created_at', operator: 'in range', value: ['2026-01-01', '2026-02-01'] }],
      { filterAttributes: [dateAttribute] },
    )

    expect(view.getByRole('group', { name: 'Created at - in range' })).toBeInTheDocument()
  })

  it('omits the operator from the label for single-operator attributes', async () => {
    const view = renderFilterSelector([{ name: 'ticket.title', operator: 'matches', value: 'x' }], {
      filterAttributes: [{ name: 'ticket.title', label: 'Title', operators: ['matches'] }],
    })

    // Plain field label, no ` - operator` suffix, and no per-row legend group.
    expect(view.getByLabelText('Title')).toBeInTheDocument()
    expect(view.queryByRole('group', { name: /Title/ })).not.toBeInTheDocument()
  })

  it('makes a multi-operator attribute expand-only in the picker (parent not selectable)', async () => {
    const view = renderFilterSelector([], {
      filterAttributes: [
        {
          name: 'ticket.created_at',
          label: 'Created at',
          operators: ['in range', 'within last (relative)'],
          attributeFieldType: 'datetime',
        },
      ],
    })

    await view.events.click(view.getByRole('button', { name: 'Add filter' }))

    // The attribute node only expands to its operators — it isn't itself
    // selectable, so the user must pick a specific operator.
    const parent = await view.findByRole('button', { name: 'Created at' })
    expect(parent).toHaveAccessibleDescription('This item expands to show more options')
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
