// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { waitFor } from '@testing-library/vue'
import { defineComponent } from 'vue'

import renderComponent from '#tests/support/components/renderComponent.ts'

import { useKeepAliveHooks } from '../useKeepAliveHooks.ts'

const renderDummyComponent = (args: Parameters<typeof useKeepAliveHooks>[0]) => {
  const ChildComponent = defineComponent({
    setup() {
      useKeepAliveHooks(args)

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

describe('useKeepAliveHooks', () => {
  it('should invoke callbacks at the right time', async () => {
    const onInitialActivated = vi.fn()
    const onActivated = vi.fn()
    const onReactivated = vi.fn()
    const onDeactivated = vi.fn()

    const component = renderDummyComponent({
      onInitialActivated,
      onReactivated,
      onDeactivated,
      onActivated,
    })

    await waitFor(() => expect(onInitialActivated).toHaveBeenCalledTimes(1))

    expect(onReactivated).not.toHaveBeenCalled()

    expect(onActivated).toHaveBeenCalledTimes(1)

    await component.rerender({ visible: false })
    await waitFor(() => expect(onDeactivated).toHaveBeenCalledTimes(1))

    await component.rerender({ visible: true })
    await waitFor(() => expect(onReactivated).toHaveBeenCalledTimes(1))

    expect(onInitialActivated).toHaveBeenCalledTimes(1)
  })
})
