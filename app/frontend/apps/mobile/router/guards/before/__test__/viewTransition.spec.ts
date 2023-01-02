// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { RouteLocationNormalized } from 'vue-router'
import { useViewTransition } from '@mobile/components/transition/TransitionViewNavigation'
import viewTransition from '../viewTransition'

const getViewTransition = () => {
  const { viewTransition } = useViewTransition()

  return viewTransition.value
}

describe('viewTransition', () => {
  it('should have replace as view transition, because one is the default level (and from has no level)', () => {
    const from = {} as RouteLocationNormalized
    const to = {
      meta: {
        level: 1,
      },
    } as RouteLocationNormalized
    const next = vi.fn()

    viewTransition(to, from, next)

    expect(getViewTransition()).toEqual('replace')
  })

  it('should have next as view transition', () => {
    const from = {
      meta: {
        level: 1,
      },
    } as RouteLocationNormalized
    const to = {
      meta: {
        level: 2,
      },
    } as RouteLocationNormalized
    const next = vi.fn()

    viewTransition(to, from, next)

    expect(getViewTransition()).toEqual('next')
  })

  it('should have prev as view transition', () => {
    const from = {
      meta: {
        level: 2,
      },
    } as RouteLocationNormalized
    const to = {
      meta: {
        level: 1,
      },
    } as RouteLocationNormalized
    const next = vi.fn()

    viewTransition(to, from, next)

    expect(getViewTransition()).toEqual('prev')
  })

  it('should have replace for not existing level on target route', () => {
    const from = {
      meta: {
        level: 2,
      },
    } as RouteLocationNormalized
    const to = {
      meta: {},
    } as RouteLocationNormalized
    const next = vi.fn()

    viewTransition(to, from, next)

    expect(getViewTransition()).toEqual('replace')
  })
})
