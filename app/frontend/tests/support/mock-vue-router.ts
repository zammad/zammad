// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

vi.mock('vue-router', async () => {
  const module = await vi.importActual<typeof import('vue-router')>('vue-router')

  return {
    ...module,
    onBeforeRouteUpdate: vi.fn(),
    onBeforeRouteLeave: vi.fn(),
  }
})

// this function never did anything, `vi.mock` is always executed as the first statement,
// but vitest 5 now fails with a hard error if it sees `vi.mock` being called ouside of the top-level scope.
// keeping the function for backwards compatibility, but it is not needed anymore
export const mockRouterHooks = () => undefined
