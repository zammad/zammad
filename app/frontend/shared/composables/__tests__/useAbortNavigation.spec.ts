// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { describe, it, expect, vi, beforeEach } from 'vitest'

import { mockRouterHooks } from '#tests/support/mock-vue-router.ts'

import { useAbortNavigation } from '../useAbortNavigation.ts'

const waitForVariantConfirmationMock = vi.fn()

mockRouterHooks()

vi.mock('#shared/composables/useConfirmation.ts', () => ({
  useConfirmation: () => ({
    waitForVariantConfirmation: waitForVariantConfirmationMock,
  }),
}))

describe('useAbortNavigation', () => {
  let confirmCallbackMock: ReturnType<typeof vi.fn>
  let shouldConfirmNavigationMock: ReturnType<typeof vi.fn>

  beforeEach(() => {
    confirmCallbackMock = vi.fn()
    shouldConfirmNavigationMock = vi.fn()
  })

  it('allows navigation if shouldConfirmNavigation returns false', async () => {
    shouldConfirmNavigationMock.mockReturnValue(false)

    useAbortNavigation({
      confirmCallback: confirmCallbackMock,
      shouldConfirmNavigation: <() => boolean>shouldConfirmNavigationMock,
    })

    expect(waitForVariantConfirmationMock).not.toHaveBeenCalled()
  })

  it('aborts navigation if confirmation is not given', async () => {
    shouldConfirmNavigationMock.mockReturnValue(true)
    waitForVariantConfirmationMock.mockResolvedValue(false)

    useAbortNavigation({
      confirmCallback: confirmCallbackMock,
      shouldConfirmNavigation: <() => boolean>shouldConfirmNavigationMock,
    })

    // expect(result).toBe(false)
    // expect(waitForVariantConfirmationMock).toHaveBeenCalledWith('unsaved')
    expect(confirmCallbackMock).not.toHaveBeenCalled()
  })

  it.todo('confirms navigation if confirmation is given', async () => {
    shouldConfirmNavigationMock.mockReturnValue(true)
    waitForVariantConfirmationMock.mockResolvedValue(true)

    useAbortNavigation({
      confirmCallback: confirmCallbackMock,
      shouldConfirmNavigation: <() => boolean>shouldConfirmNavigationMock,
    })

    // expect(result).toBe(true)
    // expect(waitForVariantConfirmationMock).toHaveBeenCalledWith('unsaved')
    expect(confirmCallbackMock).toHaveBeenCalled()
  })

  it.todo(
    'handles onBeforeRouteLeave similarly to onBeforeRouteUpdate',
    async () => {
      shouldConfirmNavigationMock.mockReturnValue(true)
      waitForVariantConfirmationMock.mockResolvedValue(true)

      useAbortNavigation({
        confirmCallback: confirmCallbackMock,
        shouldConfirmNavigation: <() => boolean>shouldConfirmNavigationMock,
      })

      // expect(result).toBe(true)
      // expect(waitForVariantConfirmationMock).toHaveBeenCalledWith('unsaved')
      expect(confirmCallbackMock).toHaveBeenCalled()
    },
  )
})
