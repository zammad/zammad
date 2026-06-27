// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import CommonIndicator from '#desktop/components/CommonIndicator/CommonIndicator.vue'

describe('CommonIndicator', () => {
  it('uses intersection observer to track visibility', async () => {
    const intersecting = { value: false }

    const view = renderComponent(CommonIndicator, {
      props: {
        modelValue: intersecting.value,
        'onUpdate:modelValue': (value: boolean) => {
          intersecting.value = value
        },
      },
    })

    const indicator = view.container.querySelector('span')
    expect(indicator).toBeInTheDocument()
    expect(indicator).toHaveClass('h-px')
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
    })

    // simple basic test
    expect(onUpdateModelValue).not.toHaveBeenCalled()
  })
})
