// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

export const mockRouterHooks = () => {
  vi.mock('vue-router', async () => {
    const module =
      await vi.importActual<typeof import('vue-router')>('vue-router')

    return {
      ...module,
      onBeforeRouteUpdate: vi.fn(),
      onBeforeRouteLeave: vi.fn(),
    }
  })
}
