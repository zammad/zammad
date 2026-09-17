// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { ApolloLink, execute, gql, Observable } from '@apollo/client/core'

import log from '#shared/utils/log.ts'

import { setAuthenticationInvalidated } from '../../utils/authenticationState.ts'
import authenticationGenerationLink from '../authenticationGeneration.ts'
import debugLink from '../debug.ts'

const queryDocument = gql`
  query sample {
    sample {
      id
    }
  }
`

const notAuthorizedResult = {
  data: null,
  errors: [
    {
      message: 'Authentication required',
      extensions: { type: 'Exceptions::NotAuthorized' },
    },
  ],
}

// Starts the operation, but leaves it in flight until 'emitResult' is called, so
//  that the authentication state can still change in the meantime.
const executeWithDeferredResult = (result: unknown, leadingLinks: ApolloLink[] = []) => {
  let emitResult: () => void

  const terminatingLink = new ApolloLink(
    () =>
      new Observable((observer) => {
        emitResult = () => {
          observer.next(result as never)
          observer.complete()
        }
      }),
  )

  const finished = new Promise<void>((resolve) => {
    execute(ApolloLink.from([...leadingLinks, debugLink, terminatingLink]), {
      query: queryDocument,
    }).subscribe({
      next: () => {},
      error: () => resolve(),
      complete: () => resolve(),
    })
  })

  return { emitResult: () => emitResult(), finished }
}

const executeWithResult = (result: unknown, leadingLinks: ApolloLink[] = []) => {
  const { emitResult, finished } = executeWithDeferredResult(result, leadingLinks)

  emitResult()

  return finished
}

const responseLogCalls = (calls: unknown[][]) =>
  calls.filter((call) => String(call[0]).startsWith('[GraphQL - Response]'))

describe('debugLink', () => {
  let previousLevel: log.LogLevelNumbers

  beforeEach(() => {
    previousLevel = log.getLevel()
    log.setLevel('debug', false)
  })

  afterEach(() => {
    log.setLevel(previousLevel, false)
    setAuthenticationInvalidated(false)
  })

  it('logs the response of an operation', async () => {
    const debugSpy = vi.spyOn(log, 'debug').mockImplementation(() => {})

    await executeWithResult({ data: { sample: { id: 1 } } })

    expect(responseLogCalls(debugSpy.mock.calls)).toHaveLength(1)
  })

  it('logs the response of a failed operation', async () => {
    const debugSpy = vi.spyOn(log, 'debug').mockImplementation(() => {})

    await executeWithResult(notAuthorizedResult)

    expect(responseLogCalls(debugSpy.mock.calls)).toHaveLength(1)
  })

  it('skips the response of an expected authentication error', async () => {
    setAuthenticationInvalidated(true)

    const debugSpy = vi.spyOn(log, 'debug').mockImplementation(() => {})

    await executeWithResult(notAuthorizedResult)

    expect(responseLogCalls(debugSpy.mock.calls)).toHaveLength(0)
  })

  it('skips the response of an operation which belongs to a previous authentication', async () => {
    const debugSpy = vi.spyOn(log, 'debug').mockImplementation(() => {})

    const { emitResult, finished } = executeWithDeferredResult(notAuthorizedResult, [
      authenticationGenerationLink,
    ])

    // Logout and login again, while the operation is still in flight.
    setAuthenticationInvalidated(true)
    setAuthenticationInvalidated(false)

    emitResult()

    await finished

    expect(responseLogCalls(debugSpy.mock.calls)).toHaveLength(0)
  })
})
