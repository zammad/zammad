// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { afterAll } from 'vitest'
import { ref } from 'vue'

import { useDebouncedLoading } from '#shared/composables/useDebouncedLoading.ts'

describe('useDebouncedLoading', () => {
  vi.useFakeTimers()

  afterAll(() => {
    vi.useRealTimers()
  })

  it('returns loading and debouncedLoading refs', () => {
    const { loading, debouncedLoading } = useDebouncedLoading()

    expect(loading.value).toBe(false)
    expect(debouncedLoading.value).toBeDefined()
  })

  it('debounces a loading state and set it to true after the default of 300ms', async () => {
    const { loading, debouncedLoading } = useDebouncedLoading()

    setTimeout(() => {
      loading.value = true
    }, 300)

    expect(debouncedLoading.value).toBe(false)

    await vi.runAllTimersAsync()

    expect(debouncedLoading.value).toBe(true)
  })

  it('accepts isLoading ref', async () => {
    const { debouncedLoading } = useDebouncedLoading({
      isLoading: ref(true),
    })

    await vi.runAllTimersAsync()

    expect(debouncedLoading.value).toBe(true)
  })

  it('debounces isLoading ref and updates it after default of 300ms', async () => {
    const isLoading = ref(false)

    const { debouncedLoading } = useDebouncedLoading({
      isLoading,
    })

    setTimeout(() => {
      isLoading.value = true
    }, 300)

    await vi.runAllTimersAsync()

    expect(debouncedLoading.value).toBe(true)
  })
})
