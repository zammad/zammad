// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { waitFor } from '@testing-library/vue'
import { defineComponent } from 'vue'

import renderComponent from '#tests/support/components/renderComponent.ts'

import { useReactivate } from '#shared/composables/useReactivate.ts'

const renderDummyComponent = (
  onActivatedCallback: () => void,
  onDeactivatedCallback: () => void,
) => {
  const ChildComponent = defineComponent({
    setup() {
      useReactivate(onActivatedCallback, onDeactivatedCallback)

      return () => 'Child Component'
    },
  })

  return renderComponent(
    {
      components: { ChildComponent },
      props: {
        visible: {
          type: Boolean,
          required: true,
        },
      },
      template: `
      <KeepAlive>
        <ChildComponent v-if="visible" />
      </KeepAlive>
    `,
    },
    { props: { visible: true } },
  )
}

describe('useReactivate', () => {
  it('does not call the activated callback on initial mount', () => {
    const onActivatedCallback = vi.fn()
    const onDeactivatedCallback = vi.fn()

    renderDummyComponent(onActivatedCallback, onDeactivatedCallback)

    expect(onActivatedCallback).not.toHaveBeenCalled()
  })

  it('calls the deactivated and activated callbacks when kept alive and reactivated', async () => {
    const onActivatedCallback = vi.fn()
    const onDeactivatedCallback = vi.fn()

    const component = renderDummyComponent(onActivatedCallback, onDeactivatedCallback)

    await component.rerender({ visible: false })
    await waitFor(() => expect(onDeactivatedCallback).toHaveBeenCalledTimes(1))

    expect(onActivatedCallback).not.toHaveBeenCalled()

    await component.rerender({ visible: true })
    await waitFor(() => expect(onActivatedCallback).toHaveBeenCalledTimes(1))
  })
})
