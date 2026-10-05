// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { ref } from 'vue'

import { waitForNextTick } from '#tests/support/utils.ts'

import { useOffsetBottomWithin } from '../useOffsetBottomWithin.ts'

// jsdom has neither layout nor a ResizeObserver, so report fixed boxes and resize on demand.
const resizeCallbacks = new Set<ResizeObserverCallback>()

class ResizeObserverStub {
  constructor(private callback: ResizeObserverCallback) {}

  observe() {
    resizeCallbacks.add(this.callback)
    this.callback([], this as unknown as ResizeObserver)
  }

  unobserve() {}

  disconnect() {
    resizeCallbacks.delete(this.callback)
  }
}

const resize = () =>
  resizeCallbacks.forEach((callback) => callback([], {} as unknown as ResizeObserver))

const createElementAt = (top: number, height = 0) => {
  const element = document.createElement('div')

  element.getBoundingClientRect = () => ({ top, bottom: top + height }) as DOMRect

  return element
}

describe('useOffsetBottomWithin', () => {
  beforeEach(() => {
    vi.stubGlobal('ResizeObserver', ResizeObserverStub)
    resizeCallbacks.clear()
  })

  afterEach(() => {
    vi.unstubAllGlobals()
  })

  it('measures from the top edge of the container to the bottom edge of the element', async () => {
    const offsetBottom = useOffsetBottomWithin(
      ref(createElementAt(-28, 24)),
      ref(createElementAt(-40, 48)),
    )

    await waitForNextTick()

    expect(offsetBottom.value).toBe(36)
  })

  it('measures again when the container is resized', async () => {
    const element = createElementAt(52, 24)
    const offsetBottom = useOffsetBottomWithin(ref(element), ref(createElementAt(0)))

    await waitForNextTick()

    element.getBoundingClientRect = () => ({ top: 12, bottom: 36 }) as DOMRect
    resize()

    expect(offsetBottom.value).toBe(36)
  })

  it('reports no offset while the element is not rendered', async () => {
    const offsetBottom = useOffsetBottomWithin(() => null, ref(createElementAt(0)))

    await waitForNextTick()

    expect(offsetBottom.value).toBe(0)
  })
})
