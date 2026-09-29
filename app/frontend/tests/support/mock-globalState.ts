// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { effectScope } from 'vue'

const globalStates = new Map<() => unknown, unknown>()

// Stands in for `createGlobalState` from VueUse: still one instance per factory,
//   but `resetGlobalStates()` lets every example start from a fresh one.
//
// The `vi.mock('@vueuse/core', ...)` call itself stays in the spec file, since
//   Vitest hoists it per module:
//
//   vi.mock('@vueuse/core', async (importOriginal) => ({
//     ...(await importOriginal<typeof import('@vueuse/core')>()),
//     createGlobalState: (await import('#tests/support/mock-globalState.ts')).createGlobalState,
//   }))
export const createGlobalState = <T>(factory: () => T) => {
  return () => {
    if (!globalStates.has(factory)) globalStates.set(factory, effectScope(true).run(factory))

    return globalStates.get(factory) as T
  }
}

export const resetGlobalStates = () => globalStates.clear()
