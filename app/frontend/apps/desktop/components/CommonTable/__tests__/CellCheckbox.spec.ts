// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { describe, it, expect } from 'vitest'

import renderComponent from '#tests/support/components/renderComponent.ts'

import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import CellCheckbox from '../CellContent/CellCheckbox.vue'

describe('CellCheckbox.vue', () => {
  const id = convertToGraphQLId('Ticket', 1)
  const item = { id }
  const itemIds = new Set([id])

  it('renders correctly when the item is checked', () => {
    const wrapper = renderComponent(CellCheckbox, {
      props: { item, itemIds },
    })

    expect(wrapper.getByRole('checkbox')).toBeChecked()
    expect(wrapper.getByIconName('check-square')).toBeInTheDocument()
  })

  it('renders correctly when the item is not checked', () => {
    const wrapper = renderComponent(CellCheckbox, {
      props: { item, itemIds: new Set() },
    })

    expect(wrapper.getByRole('checkbox')).not.toBeChecked()
    expect(wrapper.getByIconName('square')).toBeInTheDocument()
  })

  it('is disabled when item policy does not allow update', () => {
    const wrapper = renderComponent(CellCheckbox, {
      props: { item: { ...item, policy: { update: false } }, itemIds },
    })

    expect(wrapper.getByRole('checkbox')).toHaveClass('opacity-30')
    expect(wrapper.getByRole('checkbox')).toBeDisabled()
  })

  it('is disabled when item is set', () => {
    const wrapper = renderComponent(CellCheckbox, {
      props: { item: { ...item, disabled: true }, itemIds },
    })

    expect(wrapper.getByRole('checkbox')).toHaveClass('opacity-30')
    expect(wrapper.getByRole('checkbox')).toBeDisabled()
  })

  describe('a11y', () => {
    it('displays reason to the user why user update permission is not granted', () => {
      const wrapper = renderComponent(CellCheckbox, {
        props: { item: { ...item, policy: { update: false } }, itemIds },
      })

      const checkbox = wrapper.getByRole('checkbox')
      expect(checkbox).toHaveAttribute(
        'aria-description',
        'You do not have permission to update',
      )
    })

    it('displays reason to show missing update message to user if disabled generically', () => {
      const wrapper = renderComponent(CellCheckbox, {
        props: { item: { ...item, disabled: true }, itemIds },
      })

      const checkbox = wrapper.getByRole('checkbox')
      expect(checkbox).not.toHaveAttribute('aria-description')
    })
  })
})
