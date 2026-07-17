// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { vi } from 'vitest'

// Must stay well below the outer `testTimeout` (vite.config.mjs), which is shared across the
// whole test — not reset per wait. A wait called partway through a test only has whatever
// budget the outer timeout has left, so equal values (as CI's used to be, 30s/30s) mean the
// outer timeout — with its unhelpful "test timed out" message pointing at the wrong line —
// wins the race for any wait that runs after other awaits in the same test.
const DEFAULT_TIMEOUT = process.env.CI ? 20_000 : 1_000

/**
 * Enhanced wrapper around vi.waitUntil with better error handling and consistent timeout behavior
 * @param condition - Function that returns a truthy value when the condition is met
 * @param options - Configuration options
 * @param options.timeout - Maximum time to wait in milliseconds (defaults to 1000ms in dev, 20000ms in CI)
 * @param options.interval - How often to check the condition in milliseconds (defaults to 30ms)
 * @param options.message - Custom error message to show on timeout
 */
export const waitUntil = <T>(
  condition: () => T | false | Promise<T | false>,
  timeout = DEFAULT_TIMEOUT,
) => {
  return vi.waitUntil(condition, timeout)
}

/**
 * Enhanced wrapper around vi.waitFor with better error handling and consistent timeout behavior
 * @param callback - Function that should not throw an error when successful
 * @param options - Configuration options
 * @param options.timeout - Maximum time to wait in milliseconds (defaults to 1000ms in dev, 20000ms in CI)
 * @param options.interval - How often to check the condition in milliseconds (defaults to 30ms)
 * @param options.message - Custom error message to show on timeout
 */
export const waitFor = <T>(callback: () => T | Promise<T>, timeout = DEFAULT_TIMEOUT) => {
  return vi.waitFor(callback, timeout)
}
