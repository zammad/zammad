// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { describe, it, expect, vi, beforeEach, type Mock } from 'vitest'

import { useAbortNavigation } from '../useAbortNavigation.ts'

const waitForVariantConfirmationMock = vi.fn()
let onBeforeRouteUpdateCallback: Mock | undefined
let onBeforeRouteLeaveCallback: Mock | undefined

vi.mock('vue-router', async (importOriginal) => {
  const module = await importOriginal<typeof import('vue-router')>()

  return {
    ...module,
    onBeforeRouteUpdate: vi.fn((callback) => {
      onBeforeRouteUpdateCallback = callback as Mock
    }),
    onBeforeRouteLeave: vi.fn((callback) => {
      onBeforeRouteLeaveCallback = callback as Mock
    }),
  }
})

vi.mock('#shared/composables/useConfirmation.ts', () => ({
  useConfirmation: () => ({
    waitForVariantConfirmation: waitForVariantConfirmationMock,
  }),
}))

describe('useAbortNavigation', () => {
  let confirmCallbackMock: Mock
  let shouldConfirmNavigationMock: Mock

  beforeEach(() => {
    confirmCallbackMock = vi.fn()
    shouldConfirmNavigationMock = vi.fn()
    waitForVariantConfirmationMock.mockReset()
    onBeforeRouteUpdateCallback = undefined
    onBeforeRouteLeaveCallback = undefined
  })

  it('allows navigation if shouldConfirmNavigation returns false', async () => {
    shouldConfirmNavigationMock.mockReturnValue(false)

    useAbortNavigation({
      confirmCallback: confirmCallbackMock,
      shouldConfirmNavigation: <() => boolean>shouldConfirmNavigationMock,
    })

    const result = await onBeforeRouteUpdateCallback?.()

    expect(result).toBe(true)
    expect(waitForVariantConfirmationMock).not.toHaveBeenCalled()
    expect(confirmCallbackMock).not.toHaveBeenCalled()
  })

  it('aborts navigation if confirmation is not given', async () => {
    shouldConfirmNavigationMock.mockReturnValue(true)
    waitForVariantConfirmationMock.mockResolvedValue(false)

    useAbortNavigation({
      confirmCallback: confirmCallbackMock,
      shouldConfirmNavigation: <() => boolean>shouldConfirmNavigationMock,
    })

    const result = await onBeforeRouteUpdateCallback?.()

    expect(result).toBe(false)
    expect(waitForVariantConfirmationMock).toHaveBeenCalledWith('unsaved')
    expect(confirmCallbackMock).not.toHaveBeenCalled()
  })

  it('confirms navigation if confirmation is given', async () => {
    shouldConfirmNavigationMock.mockReturnValue(true)
    waitForVariantConfirmationMock.mockResolvedValue(true)

    useAbortNavigation({
      confirmCallback: confirmCallbackMock,
      shouldConfirmNavigation: <() => boolean>shouldConfirmNavigationMock,
    })

    const result = await onBeforeRouteUpdateCallback?.()

    expect(result).toBe(true)
    expect(waitForVariantConfirmationMock).toHaveBeenCalledWith('unsaved')
    expect(confirmCallbackMock).toHaveBeenCalled()
  })

  it('handles onBeforeRouteLeave similarly to onBeforeRouteUpdate', async () => {
    shouldConfirmNavigationMock.mockReturnValue(true)
    waitForVariantConfirmationMock.mockResolvedValue(true)

    useAbortNavigation({
      confirmCallback: confirmCallbackMock,
      shouldConfirmNavigation: <() => boolean>shouldConfirmNavigationMock,
    })

    const result = await onBeforeRouteLeaveCallback?.()

    expect(result).toBe(true)
    expect(waitForVariantConfirmationMock).toHaveBeenCalledWith('unsaved')
    expect(confirmCallbackMock).toHaveBeenCalled()
  })
})
