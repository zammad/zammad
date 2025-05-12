// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import renderComponent from '#tests/support/components/renderComponent.ts'

import { KeyboardKey } from '#desktop/composables/useOrderedKeyboardEvents/types.ts'
import { useKeyboardEventBus } from '#desktop/composables/useOrderedKeyboardEvents/useKeyboardEventBus.ts'

const mountComponent = (setup: () => object | void) =>
  renderComponent({
    template: `
      <KeepAlive>
        <div/>
       </KeepAlive>`,
    setup,
  })

describe('useKeyboardEventBus', () => {
  it('allows combined keyboard events to be subscribed', async () => {
    const event = {
      handler: vi.fn(),
      key: 'test-4',
      beforeHandlerRuns: vi.fn(),
    }

    const wrapper = mountComponent(() => {
      useKeyboardEventBus([KeyboardKey.Control, 'd'], event)
    })

    await wrapper.events.keyboard('{Control>}{d}{/Control}')

    expect(event.handler).toHaveBeenCalled()
  })

  it('should subscribe to a keyboard event and run always the last one added', async () => {
    const firstEvent = {
      handler: vi.fn(),
      key: 'test',
      beforeHandlerRuns: vi.fn(),
    }

    const secondEvent = {
      handler: vi.fn(),
      key: 'test-2',
      beforeHandlerRuns: vi.fn(() => false),
    }

    const wrapper = mountComponent(() => {
      const { subscribeEvent } = useKeyboardEventBus(
        KeyboardKey.Escape,
        firstEvent,
      )

      subscribeEvent(secondEvent)
    })

    await wrapper.events.keyboard('{Escape}')

    expect(firstEvent.handler).not.toHaveBeenCalled()
    expect(secondEvent.handler).toHaveBeenCalled()
  })

  it('prevents handler execution if beforeHandlerRuns returns true', async () => {
    const event = {
      handler: vi.fn(),
      key: 'test',
      beforeHandlerRuns: vi.fn(() => true),
    }

    const wrapper = mountComponent(() => {
      useKeyboardEventBus(KeyboardKey.Escape, event)
    })

    await wrapper.events.keyboard('{Escape}')

    expect(event.handler).not.toHaveBeenCalled()

    wrapper.unmount()
  })

  it('prevents handler execution if async beforeHandlerRuns returns true', async () => {
    const event = {
      handler: vi.fn(),
      key: 'test',
      beforeHandlerRuns: vi.fn(async () => Promise.resolve(true)),
    }

    const wrapper = mountComponent(() => {
      useKeyboardEventBus(KeyboardKey.Escape, event)
    })

    await wrapper.events.keyboard('{Escape}')

    expect(event.handler).not.toHaveBeenCalled()

    wrapper.unmount()
  })
})
