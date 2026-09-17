// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { ApolloLink, execute, gql, Observable } from '@apollo/client/core'

import emitter from '#shared/utils/emitter.ts'
import log from '#shared/utils/log.ts'

import { setAuthenticationInvalidated } from '../../utils/authenticationState.ts'
import authenticationGenerationLink from '../authenticationGeneration.ts'
import errorLink from '../error.ts'

const queryDocument = gql`
  query sample {
    sample {
      id
    }
  }
`

const notAuthorizedResult = {
  errors: [
    {
      message: 'Authentication required',
      extensions: { type: 'Exceptions::NotAuthorized' },
    },
  ],
}

const executeOperation = (...links: ApolloLink[]) =>
  new Promise<void>((resolve) => {
    execute(ApolloLink.from(links), { query: queryDocument }).subscribe({
      next: () => {},
      error: () => resolve(),
      complete: () => resolve(),
    })
  })

const errorResponseLink = new ApolloLink(
  () =>
    new Observable((observer) => {
      observer.next(notAuthorizedResult)
      observer.complete()
    }),
)

// Answers with the authentication error only when the returned callback is
//  called, so that the authentication can change while the operation is still
//  in flight.
const createDeferredErrorLink = () => {
  let sendResponse = () => {}

  const link = new ApolloLink(
    () =>
      new Observable((observer) => {
        sendResponse = () => {
          observer.next(notAuthorizedResult)
          observer.complete()
        }
      }),
  )

  return { link, sendResponse: () => sendResponse() }
}

const executeWithError = () => executeOperation(errorLink, errorResponseLink)

describe('errorLink', () => {
  afterEach(() => {
    setAuthenticationInvalidated(false)
  })

  it('reports an authentication error and invalidates the session', async () => {
    const emitSpy = vi.spyOn(emitter, 'emit')
    const errorSpy = vi.spyOn(log, 'error').mockImplementation(() => {})

    await executeWithError()

    expect(emitSpy).toHaveBeenCalledWith('session-invalid')
    expect(errorSpy).toHaveBeenCalled()
  })

  it('stays quiet about an authentication error when the authentication was already invalidated', async () => {
    setAuthenticationInvalidated(true)

    const emitSpy = vi.spyOn(emitter, 'emit')
    const errorSpy = vi.spyOn(log, 'error').mockImplementation(() => {})
    const debugSpy = vi.spyOn(log, 'debug').mockImplementation(() => {})

    await executeWithError()

    expect(emitSpy).not.toHaveBeenCalledWith('session-invalid')
    expect(errorSpy).not.toHaveBeenCalled()
    expect(debugSpy).toHaveBeenCalledWith(
      expect.stringContaining(
        '[GraphQL error - Exceptions::NotAuthorized]: Authentication required',
      ),
    )
  })

  it('keeps the new session when a response of the previous session arrives after a new login', async () => {
    const emitSpy = vi.spyOn(emitter, 'emit')
    const errorSpy = vi.spyOn(log, 'error').mockImplementation(() => {})
    const debugSpy = vi.spyOn(log, 'debug').mockImplementation(() => {})

    const { link, sendResponse } = createDeferredErrorLink()

    const finished = executeOperation(authenticationGenerationLink, errorLink, link)

    // Logout and login again, while the operation is still in flight.
    setAuthenticationInvalidated(true)
    setAuthenticationInvalidated(false)

    sendResponse()

    await finished

    expect(emitSpy).not.toHaveBeenCalledWith('session-invalid')
    expect(errorSpy).not.toHaveBeenCalled()
    expect(debugSpy).toHaveBeenCalledWith(
      expect.stringContaining('(expected, it belongs to a previous authentication)'),
    )
  })
})
