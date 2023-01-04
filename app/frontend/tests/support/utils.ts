// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { nextTick } from 'vue'
import type { MockGraphQLInstance } from './mock-graphql-api'

export const waitForTimeout = async (milliseconds = 0) => {
  return new Promise((resolve) => {
    setTimeout(resolve, milliseconds)
  })
}

export const waitForNextTick = async (withTimeout = false) => {
  if (withTimeout) {
    await nextTick()

    return new Promise((resolve) => {
      setTimeout(resolve, 0)
    })
  }

  return nextTick()
}

export const waitUntil = async (
  condition: () => unknown,
  msThreshold = 1000,
) => {
  return new Promise<void>((resolve, reject) => {
    const start = Date.now()
    const max = start + msThreshold
    const interval = setInterval(() => {
      if (condition()) {
        clearInterval(interval)
        resolve()
      }
      if (max < Date.now()) {
        clearInterval(interval)
        reject(new Error('Timeout'))
      }
    }, 30)
  })
}

export const waitUntilApisResolved = (...mockApis: MockGraphQLInstance[]) => {
  return waitUntil(() => mockApis.every((mock) => mock.calls.resolve))
}

// The apollo cache always asks for a field, even if it's marked as optional
// this function returns a proxy that will return "null" on properties not defined
// in the initial object.
export const nullableMock = <T extends object>(obj: T): T => {
  const skipProperties = new Set(['_id', 'id', Symbol.toStringTag])

  return new Proxy(obj, {
    get(target, prop, receiver) {
      if (!Reflect.has(target, prop) && !skipProperties.has(prop)) {
        return null
      }
      const value = Reflect.get(target, prop, receiver)
      if (Array.isArray(value)) {
        return value.map(nullableMock)
      }
      if (typeof value === 'object' && value !== null) {
        return nullableMock(value)
      }
      return value
    },
  })
}
