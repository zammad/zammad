// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { RouteLocationNormalized } from 'vue-router'
import viewTransition from '@mobile/router/guards/before/viewTransition'
import useViewTransition from '@mobile/composables/useViewTransition'

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
    const next = jest.fn()

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
    const next = jest.fn()

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
    const next = jest.fn()

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
    const next = jest.fn()

    viewTransition(to, from, next)

    expect(getViewTransition()).toEqual('replace')
  })
})
