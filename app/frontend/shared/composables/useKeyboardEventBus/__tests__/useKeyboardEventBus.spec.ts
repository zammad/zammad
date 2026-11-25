// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { defineComponent } from 'vue'

import renderComponent from '#tests/support/components/renderComponent.ts'

import { KeyboardKey } from '#shared/composables/useKeyboardEventBus/types.ts'
import {
  useKeyboardEventBus,
  useKeyboardShortcutEventBus,
} from '#shared/composables/useKeyboardEventBus/useKeyboardEventBus.ts'

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
      const { subscribeEvent } = useKeyboardEventBus(KeyboardKey.Escape, firstEvent)

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

describe('useKeyboardShortcutEventBus', () => {
  const mountShortcuts = (setup: () => void) =>
    renderComponent({
      template: '<input aria-label="Field" />',
      setup,
    })

  it('runs the handler for the pressed combination and keeps the key from being typed', async () => {
    const handler = vi.fn()

    const wrapper = mountShortcuts(() => {
      useKeyboardShortcutEventBus('shift+c', { key: 'shift-c', handler })
    })

    await wrapper.events.keyboard('c')
    expect(handler).not.toHaveBeenCalled()

    await wrapper.events.keyboard('{Shift>}c{/Shift}')
    expect(handler).toHaveBeenCalledTimes(1)
    expect(handler.mock.calls[0][0].defaultPrevented).toBe(true)

    wrapper.unmount()
  })

  it('does not replay a held key when a modifier is released first', async () => {
    const plainHandler = vi.fn()
    const shiftHandler = vi.fn()

    const wrapper = mountShortcuts(() => {
      useKeyboardShortcutEventBus('c', { key: 'plain-c', handler: plainHandler })
      useKeyboardShortcutEventBus('shift+c', { key: 'shift-c', handler: shiftHandler })
    })

    await wrapper.events.keyboard('{Shift>}{c>}{/Shift}{/c}')

    expect(shiftHandler).toHaveBeenCalledTimes(1)
    expect(plainHandler).not.toHaveBeenCalled()

    wrapper.unmount()
  })

  it('ignores auto-repeated keydown events of a held key', async () => {
    const handler = vi.fn()

    const wrapper = mountShortcuts(() => {
      useKeyboardShortcutEventBus('h', { key: 'h', handler })
    })

    await wrapper.events.keyboard('{h>3/}')

    expect(handler).toHaveBeenCalledTimes(1)

    wrapper.unmount()
  })

  it('keeps the repeated presses of a held key from being typed', async () => {
    const handler = vi.fn()

    const wrapper = mountShortcuts(() => {
      useKeyboardShortcutEventBus('h', { key: 'h', handler })
    })

    wrapper.getByLabelText('Field').focus()
    await wrapper.events.keyboard('{h>3/}')

    expect(handler).toHaveBeenCalledTimes(1)
    expect(wrapper.getByLabelText('Field')).toHaveValue('')

    wrapper.unmount()
  })

  it('runs the subscriber added last and falls through an inactive one', async () => {
    const firstHandler = vi.fn()
    const secondHandler = vi.fn()
    let isSecondActive = true

    const wrapper = mountShortcuts(() => {
      useKeyboardShortcutEventBus('h', { key: 'first', handler: firstHandler })
      useKeyboardShortcutEventBus('h', {
        key: 'second',
        handler: secondHandler,
        isActive: () => isSecondActive,
      })
    })

    await wrapper.events.keyboard('h')

    expect(secondHandler).toHaveBeenCalledTimes(1)
    expect(firstHandler).not.toHaveBeenCalled()

    isSecondActive = false

    await wrapper.events.keyboard('h')

    expect(secondHandler).toHaveBeenCalledTimes(1)
    expect(firstHandler).toHaveBeenCalledTimes(1)

    wrapper.unmount()
  })

  it('lets the key through when no subscriber is active', async () => {
    const handler = vi.fn()

    const wrapper = mountShortcuts(() => {
      useKeyboardShortcutEventBus('h', { key: 'h', handler, isActive: () => false })
    })

    await wrapper.events.type(wrapper.getByLabelText('Field'), 'h')

    expect(handler).not.toHaveBeenCalled()
    expect(wrapper.getByLabelText('Field')).toHaveValue('h')

    wrapper.unmount()
  })

  it('unsubscribes on unmount', async () => {
    const handler = vi.fn()

    const wrapper = mountShortcuts(() => {
      useKeyboardShortcutEventBus('h', { key: 'h', handler })
    })

    const { events } = wrapper

    wrapper.unmount()

    await events.keyboard('h')

    expect(handler).not.toHaveBeenCalled()
  })

  it('unsubscribes while deactivated in a keep-alive cache and resubscribes when reactivated', async () => {
    const handler = vi.fn()

    const ChildComponent = defineComponent({
      setup() {
        useKeyboardShortcutEventBus('h', { key: 'kept-alive', handler })

        return () => 'Child Component'
      },
    })

    const wrapper = renderComponent(
      {
        components: { ChildComponent },
        props: { visible: { type: Boolean, required: true } },
        template: '<KeepAlive><ChildComponent v-if="visible" /></KeepAlive>',
      },
      { props: { visible: true } },
    )

    await wrapper.rerender({ visible: false })
    await wrapper.events.keyboard('h')

    expect(handler).not.toHaveBeenCalled()

    await wrapper.rerender({ visible: true })
    await wrapper.events.keyboard('h')

    expect(handler).toHaveBeenCalledTimes(1)

    wrapper.unmount()
  })
})
