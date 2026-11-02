// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { effectScope } from 'vue'

import { mockedApolloClient } from '#tests/graphql/builders/mocks.ts'
import { waitFor } from '#tests/support/vitest-wrapper.ts'

import { LogoutDocument } from '#shared/graphql/mutations/logout.api.ts'
import { ApplicationBuildChecksumDocument } from '#shared/graphql/queries/applicationBuildChecksum.api.ts'

import { useMutation, useQuery } from '../vueApollo.ts'

import type { EffectScope } from 'vue'

const { detachedScopes } = vi.hoisted(() => ({ detachedScopes: [] as EffectScope[] }))

vi.mock('vue', async (importOriginal) => {
  const vue = await importOriginal<typeof import('vue')>()

  return {
    ...vue,
    effectScope: (detached?: boolean) => {
      const scope = vue.effectScope(detached)
      if (detached) detachedScopes.push(scope)
      return scope
    },
  }
})

beforeEach(() => {
  detachedScopes.length = 0
})

describe('vueApollo', () => {
  it('creates the composable inside the current effect scope and disposes it with the scope', async () => {
    const scope = effectScope()

    const query = scope.run(() => useQuery(ApplicationBuildChecksumDocument))!
    await waitFor(() => expect(query.result.value).toBeDefined())
    expect(mockedApolloClient.getObservableQueries().size).toBe(1)

    scope.stop()

    expect(mockedApolloClient.getObservableQueries().size).toBe(0)
  })

  it('leaves a mutation created inside an effect scope to that scope', async () => {
    const scope = effectScope()

    const mutation = scope.run(() => useMutation(LogoutDocument))!

    expect(detachedScopes).toHaveLength(0)

    await expect(mutation.mutate()).resolves.toBeTruthy()

    scope.stop()
  })

  it('stops the scope a mutation created outside of one falls back to', async () => {
    const mutation = useMutation(LogoutDocument)

    expect(detachedScopes).toHaveLength(1)
    expect(detachedScopes[0].active, 'the fallback scope is not left behind').toBe(false)

    // The mutation has to stay usable without the scope it was set up in.
    const result = await mutation.mutate()

    expect(result?.data?.logout).toBeTruthy()
    expect(mutation.called.value).toBe(true)
    expect(mutation.loading.value).toBe(false)
  })

  it('warns about a query created outside of an effect scope instead of hiding it', async (context) => {
    context.skipConsole = true

    useQuery(ApplicationBuildChecksumDocument)

    expect(detachedScopes).toHaveLength(0)
    expect(console.warn).toHaveBeenCalledWith(
      expect.stringContaining('useQuery() is called outside of an active effect scope'),
    )
  })
})
