// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import isRouteLink from '@common/router/utils/isRouteLink'
import { useRouter } from 'vue-router'

// Add a mocked router resolve function for the success case.
jest.mock('vue-router', () => ({
  useRouter: jest.fn(() => ({
    resolve: () => {
      return {
        name: 'RouteName',
        matched: ['RouteName'],
      }
    },
  })),
}))

const router = useRouter as jest.Mock

describe('isRouteLink', () => {
  it('is correct route link', () => {
    expect(isRouteLink('ticket/12')).toEqual(true)
  })

  it('is not a correct route link, because error route was resolved', () => {
    router.mockImplementationOnce(() => ({
      resolve: () => {
        return {
          name: 'Error',
          matched: ['Error'],
        }
      },
    }))

    expect(isRouteLink('not-existing')).toEqual(false)
  })

  it('is not a correct route link, because nothing was resolved', () => {
    router.mockImplementationOnce(() => ({
      resolve: () => {
        return null
      },
    }))

    expect(isRouteLink('not-working')).toEqual(false)
  })

  it('link object is always a route link', () => {
    expect(
      isRouteLink({
        name: 'Login',
      }),
    ).toEqual(true)
  })
})
