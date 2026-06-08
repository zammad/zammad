// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { describe, it, expect } from 'vitest'

import renderComponent from '#tests/support/components/renderComponent.ts'

import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import BulkCheckbox from '../BulkCheckbox.vue'

const items = [
  {
    id: convertToGraphQLId('Ticket', 1),
  },
  {
    id: convertToGraphQLId('Ticket', 2),
  },
  {
    id: convertToGraphQLId('Ticket', 3),
  },
]

describe('BulkCheckbox.vue', () => {
  describe('checkbox markup', () => {
    it.each([
      {
        itemIds: new Set([]),
        itemCount: 'no',
        checkboxState: 'unchecked',
      },
      {
        itemIds: new Set([items.at(0)?.id]),
        itemCount: 'some',
        checkboxState: 'mixed',
      },
      {
        itemIds: new Set(items.map((item) => item.id)),
        itemCount: 'all',
        checkboxState: 'checked',
      },
    ])(
      'renders $checkboxState checkbox when $itemCount items are selected',
      ({ itemIds, checkboxState }) => {
        const wrapper = renderComponent(BulkCheckbox, {
          props: { items, itemIds },
        })

        switch (checkboxState) {
          case 'unchecked':
            expect(wrapper.getByRole('checkbox')).not.toBeChecked()
            expect(wrapper.getByIconName('square')).toBeInTheDocument()
            break
          case 'mixed':
            expect(wrapper.getByRole('checkbox')).toHaveAttribute('aria-checked', 'mixed')
            expect(wrapper.getByIconName('dash-square')).toBeInTheDocument()
            break
          case 'checked':
            expect(wrapper.getByRole('checkbox')).toBeChecked()
            expect(wrapper.getByIconName('check-square')).toBeInTheDocument()
        }
      },
    )
  })

  describe('selectable items', () => {
    it.each([
      {
        attributeName: 'policy',
        itemAttribute: { policy: { update: false } },
      },
      {
        attributeName: 'disabled',
        itemAttribute: { disabled: true },
      },
    ])('considers item $attributeName when checking for selectable items', ({ itemAttribute }) => {
      const wrapper = renderComponent(BulkCheckbox, {
        props: {
          items: [items[0], items[1], { ...items[2], ...itemAttribute }],
          itemIds: new Set([items.at(0)?.id, items.at(1)?.id]),
        },
      })

      expect(wrapper.getByRole('checkbox')).toBeChecked()
      expect(wrapper.getByIconName('check-square')).toBeInTheDocument()
    })

    it('allows disabling via disabled prop', async () => {
      const wrapper = renderComponent(BulkCheckbox, {
        props: { items, disabled: true },
      })

      expect(wrapper.getByRole('checkbox')).toBeDisabled()

      wrapper.events.click(wrapper.getByRole('checkbox'))

      expect(wrapper.emitted('select-all')).toBeFalsy()
    })
  })

  describe('component events', () => {
    it.each([
      {
        eventName: 'select-all',
        checkboxState: 'unchecked',
        itemIds: new Set([]),
      },
      {
        eventName: 'select-all',
        checkboxState: 'mixed',
        itemIds: new Set([items.at(0)?.id]),
      },
      {
        eventName: 'deselect-all',
        checkboxState: 'checked',
        itemIds: new Set(items.map((item) => item.id)),
      },
    ])(
      'emits $eventName event when $checkboxState checkbox is clicked',
      async ({ eventName, itemIds }) => {
        const wrapper = renderComponent(BulkCheckbox, {
          props: { items, itemIds },
        })

        await wrapper.events.click(wrapper.getByRole('checkbox'))

        expect(wrapper.emitted(eventName)).toBeTruthy()
      },
    )
  })

  describe('a11y', () => {
    it('has aria-controls attribute', async () => {
      const wrapper = renderComponent(BulkCheckbox, {
        props: { items },
      })

      const checkbox = wrapper.getByRole('checkbox')

      expect(checkbox).toHaveAttribute(
        'aria-controls',
        items.map((item) => `cell-checkbox-${item.id}`).join(' '),
      )

      expect(checkbox).toHaveAttribute('aria-checked', 'false')
      expect(checkbox).toHaveAttribute('aria-label', 'Select all entries')

      await wrapper.rerender({
        itemIds: new Set([items.at(0)?.id]),
      })

      expect(checkbox).toHaveAttribute('aria-checked', 'mixed')
      expect(checkbox).toHaveAttribute('aria-label', 'Select all entries')

      await wrapper.rerender({
        itemIds: new Set(items.map((item) => item.id)),
      })

      expect(checkbox).toHaveAttribute('aria-checked', 'true')
      expect(checkbox).toHaveAttribute('aria-label', 'Clear selection')
    })
  })
})
