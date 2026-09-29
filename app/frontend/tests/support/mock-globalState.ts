// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { effectScope } from 'vue'

import type { EffectScope } from 'vue'

const globalStates = new Map<() => unknown, { scope: EffectScope; state: unknown }>()

// Stands in for `createGlobalState` from VueUse: still one instance per factory,
//   but `resetGlobalStates()` lets every example start from a fresh one and
//   stops the previous one, so its listeners do not outlive the example.
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
    if (!globalStates.has(factory)) {
      const scope = effectScope(true)

      globalStates.set(factory, { scope, state: scope.run(factory) })
    }

    return globalStates.get(factory)!.state as T
  }
}

export const resetGlobalStates = () => {
  globalStates.forEach(({ scope }) => scope.stop())
  globalStates.clear()
}
