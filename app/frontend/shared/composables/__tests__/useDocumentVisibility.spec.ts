// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { effectScope, nextTick, ref, type EffectScope } from 'vue'

import { useDocumentVisibility } from '../useDocumentVisibility.ts'

const visibilityState = ref<DocumentVisibilityState>('visible')

vi.mock('@vueuse/core', () => ({
  useDocumentVisibility: () => visibilityState,
}))

let scope: EffectScope

// In a scope like a component's, so each test's watcher is disposed with it.
const setup = () => {
  scope = effectScope()

  return scope.run(() => useDocumentVisibility())!
}

describe('useDocumentVisibility', () => {
  afterEach(() => {
    scope?.stop()
    visibilityState.value = 'visible'
  })

  it('reports a shown document as visible', () => {
    const { isVisible } = setup()

    expect(isVisible.value).toBe(true)
  })

  it('reports a hidden document as not visible', () => {
    visibilityState.value = 'hidden'

    const { isVisible } = setup()

    expect(isVisible.value).toBe(false)
  })

  it('follows the document when it changes', () => {
    const { isVisible, visibilityState: state } = setup()

    visibilityState.value = 'hidden'

    expect(state.value).toBe('hidden')
    expect(isVisible.value).toBe(false)
  })

  describe('whenVisible', () => {
    it('runs the callback right away in a visible document', () => {
      const callback = vi.fn()
      const { whenVisible } = setup()

      whenVisible(callback)

      expect(callback).toHaveBeenCalledOnce()
    })

    it('holds the callback in a hidden document until it is looked at again', async () => {
      visibilityState.value = 'hidden'

      const callback = vi.fn()
      const { whenVisible } = setup()

      whenVisible(callback)

      expect(callback).not.toHaveBeenCalled()

      visibilityState.value = 'visible'
      await nextTick()

      expect(callback).toHaveBeenCalledOnce()
    })

    it('holds only the latest callback', async () => {
      visibilityState.value = 'hidden'

      const first = vi.fn()
      const second = vi.fn()
      const { whenVisible } = setup()

      whenVisible(first)
      whenVisible(second)

      visibilityState.value = 'visible'
      await nextTick()

      expect(first).not.toHaveBeenCalled()
      expect(second).toHaveBeenCalledOnce()
    })

    it('drops the callback once the timeout has passed', async () => {
      vi.useFakeTimers()
      visibilityState.value = 'hidden'

      const callback = vi.fn()
      const { whenVisible } = setup()

      whenVisible(callback, 1000)
      vi.advanceTimersByTime(1000)
      vi.useRealTimers()

      visibilityState.value = 'visible'
      await nextTick()

      expect(callback).not.toHaveBeenCalled()
    })

    it('waits as long as it takes without a timeout', async () => {
      vi.useFakeTimers()
      visibilityState.value = 'hidden'

      const callback = vi.fn()
      const { whenVisible } = setup()

      whenVisible(callback)
      vi.advanceTimersByTime(24 * 60 * 60 * 1000)
      vi.useRealTimers()

      visibilityState.value = 'visible'
      await nextTick()

      expect(callback).toHaveBeenCalledOnce()
    })
  })
})
