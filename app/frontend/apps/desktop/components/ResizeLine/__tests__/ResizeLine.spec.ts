// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { fireEvent } from '@testing-library/vue'
import { expect } from 'vitest'

import renderComponent from '#tests/support/components/renderComponent.ts'

import ResizeLine from '#desktop/components/ResizeLine/ResizeLine.vue'

describe('ResizeLine', () => {
  it('does not emit events or display line background styling when disabled.', async () => {
    const wrapper = renderComponent(ResizeLine, {
      props: {
        disabled: true,
        label: 'test-label',
      },
    })

    expect(wrapper.queryByRole('separator')).not.toBeInTheDocument()
    expect(wrapper.getByRole('button')).toBeDisabled()
    expect(wrapper.getByRole('button')).not.toHaveAccessibleName('test-label')

    await wrapper.events.click(wrapper.getByRole('button'))
    expect(wrapper.emitted('mousedown-event')).toBeUndefined()

    await fireEvent.touch(wrapper.getByRole('button'))
    expect(wrapper.emitted('touchstart-event')).toBeUndefined()

    await wrapper.events.dblClick(wrapper.getByRole('button'))
    expect(wrapper.emitted('dblclick-event')).toBeUndefined()
  })

  it('emits events and displays line background styling when enabled.', async () => {
    const wrapper = renderComponent(ResizeLine, {
      props: {
        label: 'test-label',
      },
    })

    await wrapper.events.click(wrapper.getByRole('button'))
    expect(wrapper.emitted('mousedown-event')).toBeTruthy()

    await fireEvent.touchStart(wrapper.getByRole('button'))
    expect(wrapper.emitted('touchstart-event')).toBeTruthy()

    await wrapper.events.dblClick(wrapper.getByRole('button'))
    expect(wrapper.emitted('dblclick-event')).toBeTruthy()
  })

  it('has correct a11y labels', async () => {
    const wrapper = renderComponent(ResizeLine, {
      props: {
        label: 'test-label',
        values: {
          max: 100,
          min: 10,
          current: 50,
        },
      },
    })

    expect(wrapper.getByRole('separator')).toHaveAttribute(
      'aria-valuemax',
      '100',
    )
    expect(wrapper.getByRole('separator')).toHaveAttribute(
      'aria-valuemin',
      '10',
    )
    expect(wrapper.getByRole('separator')).toHaveAttribute(
      'aria-valuenow',
      '50',
    )

    expect(wrapper.getByRole('separator')).toHaveAttribute(
      'aria-orientation',
      'horizontal',
    )

    expect(wrapper.getByLabelText('test-label')).toBeInTheDocument()

    await wrapper.rerender({
      orientation: 'horizontal',
    })

    expect(wrapper.getByRole('separator')).toHaveAttribute(
      'aria-orientation',
      'vertical',
    )
  })
})
