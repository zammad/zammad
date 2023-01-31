// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { RouteLocationNormalized, Router } from 'vue-router'
import { Walker } from '../walker'

const buildRouter = () =>
  ({
    afterEach: vi.fn(),
    back: vi.fn(),
    push: vi.fn(),
  } as any as Router)

describe('testing walker', () => {
  it('has fallback route, if no back is in history', async () => {
    const router = buildRouter()
    const walker = new Walker(router)
    expect(walker.hasBackUrl).toBe(false)
    expect(walker.getBackUrl('/fallback')).toBe('/fallback')
    await walker.back('/fallback')
    expect(router.push).toHaveBeenCalledWith('/fallback')
  })

  it('has back route, if there is back route in history', async () => {
    window.history.replaceState({ back: '/back' }, '', '/back')
    const router = buildRouter()
    const walker = new Walker(router)
    expect(walker.hasBackUrl).toBe(true)
    expect(walker.getBackUrl('/fallback')).toBe('/back')
    await walker.back('/fallback')
    expect(router.back).toHaveBeenCalled()
  })

  it('changes back route after changing route', () => {
    window.history.replaceState({ back: null }, '', '/back')

    const router = buildRouter()
    const walker = new Walker(router)

    expect(walker.hasBackUrl).toBe(false)

    const route = {} as RouteLocationNormalized

    const afterEach = vi.mocked(router.afterEach).mock.calls[0][0]

    window.history.replaceState({ back: '/back' }, '', '/back')

    afterEach(route, route)

    expect(walker.hasBackUrl).toBe(true)
    expect(walker.getBackUrl('/fallback')).toBe('/back')
  })

  it('does not cycle with ignore list match', async () => {
    window.history.replaceState(
      { back: '/tickets/1/information/customer' },
      '',
      '/tickets/1/information/customer',
    )
    const router = buildRouter()
    const walker = new Walker(router)
    await walker.back('/fallback', ['/tickets/1/information'])
    expect(router.push).toHaveBeenCalledWith('/fallback')
  })

  it('does not cycle without ignore list match', async () => {
    window.history.replaceState(
      { back: '/tickets/1/information/customer' },
      '',
      '/tickets/1/information/customer',
    )
    const router = buildRouter()
    const walker = new Walker(router)
    await walker.back('/fallback', ['/tickets/99999/information'])
    expect(router.back).toHaveBeenCalled()
  })
})
