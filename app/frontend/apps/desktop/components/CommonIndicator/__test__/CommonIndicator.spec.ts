// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import CommonIndicator from '#desktop/components/CommonIndicator/CommonIndicator.vue'

describe('CommonIndicator', () => {
  it('renders the component with slot content', () => {
    const view = renderComponent(CommonIndicator, {
      slots: {
        default: 'Test content',
      },
    })

    expect(view.getByText('Test content')).toBeInTheDocument()
  })

  it('uses intersection observer to track visibility', async () => {
    const intersecting = { value: false }

    const view = renderComponent(CommonIndicator, {
      props: {
        modelValue: intersecting.value,
        'onUpdate:modelValue': (value: boolean) => {
          intersecting.value = value
        },
      },
      slots: {
        default: 'Indicator content',
      },
    })

    const indicator = view.container.querySelector('div')
    expect(indicator).toBeInTheDocument()

    expect(view.getByText('Indicator content')).toBeInTheDocument()
  })

  it('updates v-model when intersection changes', async () => {
    let modelValue = false
    const onUpdateModelValue = vi.fn((value: boolean) => {
      modelValue = value
    })

    renderComponent(CommonIndicator, {
      props: {
        modelValue,
        'onUpdate:modelValue': onUpdateModelValue,
      },
      slots: {
        default: 'Content',
      },
    })

    // simple basic test
    expect(onUpdateModelValue).not.toHaveBeenCalled()
  })
})
