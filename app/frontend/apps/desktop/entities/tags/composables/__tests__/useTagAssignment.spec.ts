// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { gql } from '@apollo/client'
import { flushPromises } from '@vue/test-utils'
import { defineComponent } from 'vue'

import renderComponent from '#tests/support/components/renderComponent.ts'
import { waitFor } from '#tests/support/vitest-wrapper.ts'

import { NotificationTypes } from '#shared/components/CommonNotifications/types.ts'
import { useNotifications } from '#shared/components/CommonNotifications/useNotifications.ts'
import {
  mockTagAssignmentAddMutation,
  mockTagAssignmentAddMutationError,
  waitForTagAssignmentAddMutationCalls,
} from '#shared/entities/tags/graphql/mutations/assignment/add.mocks.ts'
import {
  mockTagAssignmentRemoveMutation,
  mockTagAssignmentRemoveMutationError,
  waitForTagAssignmentRemoveMutationCalls,
} from '#shared/entities/tags/graphql/mutations/assignment/remove.mocks.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'
import { getApolloClient } from '#shared/server/apollo/client.ts'
import { setAuthenticationInvalidated } from '#shared/server/apollo/utils/authenticationState.ts'
import { GraphQLErrorTypes } from '#shared/types/error.ts'

import { useTagAssignment } from '../useTagAssignment.ts'

const entity = { __typename: 'Ticket', id: convertToGraphQLId('Ticket', 1) }

const fragment = gql`
  fragment TestTags on Ticket {
    id
    tags
  }
`

const writeTags = (tags: string[]) =>
  getApolloClient().cache.writeFragment({ fragment, data: { ...entity, tags } })

const readTags = () =>
  getApolloClient().cache.readFragment<{ tags: string[] }>({
    id: getApolloClient().cache.identify(entity),
    fragment,
  })?.tags

let api: ReturnType<typeof useTagAssignment>

const mountAssignment = (tags: string[], { withoutRecord = false } = {}) => {
  writeTags(tags)

  renderComponent(
    defineComponent({
      setup() {
        api = useTagAssignment({
          entity: () => (withoutRecord ? undefined : entity),
          tags: () => readTags() ?? [],
        })

        return () => null
      },
    }),
  )
}

describe('useTagAssignment', () => {
  it('shows an added tag at once, stores it and tells the agent', async () => {
    mockTagAssignmentAddMutation({ tagAssignmentAdd: { success: true, errors: null } })
    mountAssignment(['vip'])

    expect(api.addTag('billing')).toBe(true)
    expect(readTags()).toEqual(['vip', 'billing'])

    const calls = await waitForTagAssignmentAddMutationCalls()

    expect(calls.at(-1)?.variables).toEqual({ objectId: entity.id, tag: 'billing' })

    await waitFor(() =>
      expect(useNotifications().notify).toHaveBeenCalledWith({
        type: NotificationTypes.Success,
        id: 'tag-added',
        message: 'Tag added successfully.',
      }),
    )
    expect(readTags()).toEqual(['vip', 'billing'])
  })

  it('ignores an empty tag and one the record has already', () => {
    mountAssignment(['vip'])

    expect(api.addTag('')).toBe(false)
    expect(api.addTag('vip')).toBe(false)
    expect(readTags()).toEqual(['vip'])
  })

  it('adds nothing while there is no record to add it to', () => {
    mountAssignment(['vip'], { withoutRecord: true })

    expect(api.addTag('billing')).toBe(false)
    expect(readTags()).toEqual(['vip'])
  })

  it('takes an added tag back off when the server does not store it', async () => {
    mockTagAssignmentAddMutationError('Not authorized', { type: GraphQLErrorTypes.Forbidden })
    mountAssignment(['vip'])

    api.addTag('billing')

    expect(readTags()).toEqual(['vip', 'billing'])

    await waitFor(() => expect(readTags()).toEqual(['vip']))
    expect(useNotifications().notify).toHaveBeenCalledWith(
      expect.objectContaining({
        type: NotificationTypes.Error,
        message: 'The tag could not be added.',
      }),
    )
  })

  it('undoes only the edit that failed, and keeps one made meanwhile', async () => {
    let failVipRemoval!: (error: Error) => void
    let answerBillingRemoval!: () => void

    mockTagAssignmentRemoveMutation(({ tag }) =>
      tag === 'vip'
        ? new Promise((_resolve, reject) => {
            failVipRemoval = reject
          })
        : new Promise((resolve) => {
            answerBillingRemoval = () =>
              resolve({ tagAssignmentRemove: { success: true, errors: null } })
          }),
    )
    mountAssignment(['vip', 'billing'])

    api.removeTag('vip')
    await waitForTagAssignmentRemoveMutationCalls()
    api.removeTag('billing')

    expect(readTags()).toEqual([])

    // The second removal waits until the first one is answered.
    await flushPromises()
    expect(await waitForTagAssignmentRemoveMutationCalls()).toHaveLength(1)

    failVipRemoval(new Error('Connection lost'))

    await waitFor(async () =>
      expect(
        (await waitForTagAssignmentRemoveMutationCalls()).map((call) => call.variables.tag),
      ).toEqual(['vip', 'billing']),
    )
    // Undone while the removal made meanwhile is still on its way, which it does not take back.
    expect(readTags()).toEqual(['vip'])

    answerBillingRemoval()

    await waitFor(() =>
      expect(useNotifications().notify).toHaveBeenCalledWith(
        expect.objectContaining({ id: 'tag-removed' }),
      ),
    )
    expect(readTags()).toEqual(['vip'])
  })

  it('keeps a change from elsewhere that arrives while an edit is on its way', async () => {
    let answerAddition!: () => void

    mockTagAssignmentAddMutation(
      () =>
        new Promise((resolve) => {
          answerAddition = () => resolve({ tagAssignmentAdd: { success: true, errors: null } })
        }),
    )
    mountAssignment(['vip'])

    api.addTag('billing')
    await waitForTagAssignmentAddMutationCalls()

    // The record's own update, with a tag another agent added meanwhile.
    writeTags(['vip', 'billing', 'urgent'])

    answerAddition()

    await waitFor(() =>
      expect(useNotifications().notify).toHaveBeenCalledWith(
        expect.objectContaining({ id: 'tag-added' }),
      ),
    )
    expect(readTags()).toEqual(['vip', 'billing', 'urgent'])
  })

  it('puts a removed tag back where it was, next to a change from elsewhere', async () => {
    let failRemoval!: (error: Error) => void

    mockTagAssignmentRemoveMutation(
      () =>
        new Promise((_resolve, reject) => {
          failRemoval = reject
        }),
    )
    mountAssignment(['vip', 'billing'])

    api.removeTag('vip')
    await waitForTagAssignmentRemoveMutationCalls()

    writeTags(['billing', 'urgent'])

    failRemoval(new Error('Connection lost'))

    await waitFor(() => expect(readTags()).toEqual(['vip', 'billing', 'urgent']))
  })

  it('keeps a tag the server still has when its removal and its addition again both fail', async () => {
    mockTagAssignmentRemoveMutationError('Not authorized', { type: GraphQLErrorTypes.Forbidden })
    mockTagAssignmentAddMutationError('Not authorized', { type: GraphQLErrorTypes.Forbidden })
    mountAssignment(['vip', 'billing'])

    api.removeTag('vip')
    api.addTag('vip')

    expect(readTags()).toEqual(['billing', 'vip'])

    await waitForTagAssignmentAddMutationCalls()
    await flushPromises()

    expect(readTags()).toEqual(['billing', 'vip'])
  })

  it('takes a tag off when its removal is stored and its addition again fails', async () => {
    mockTagAssignmentRemoveMutation({ tagAssignmentRemove: { success: true, errors: null } })
    mockTagAssignmentAddMutationError('Not authorized', { type: GraphQLErrorTypes.Forbidden })
    mountAssignment(['vip', 'billing'])

    api.removeTag('vip')
    api.addTag('vip')

    await waitForTagAssignmentAddMutationCalls()
    await flushPromises()

    expect(readTags()).toEqual(['billing'])
  })

  it('puts a tag that was added meanwhile back at the end when its removal fails', async () => {
    mockTagAssignmentAddMutation({ tagAssignmentAdd: { success: true, errors: null } })
    mockTagAssignmentRemoveMutationError('Not authorized', { type: GraphQLErrorTypes.Forbidden })
    mountAssignment(['vip', 'billing'])

    api.addTag('urgent')
    api.removeTag('urgent')

    await waitForTagAssignmentRemoveMutationCalls()
    await flushPromises()

    expect(readTags()).toEqual(['vip', 'billing', 'urgent'])
  })

  describe('when the agent logs out while edits are on their way', () => {
    afterEach(() => {
      setAuthenticationInvalidated(false)
    })

    // What the logout does before it waits for the server.
    const startLogout = () => {
      setAuthenticationInvalidated(true)
    }

    // The next agent is logged in.
    const logOut = () => {
      startLogout()
      setAuthenticationInvalidated(false)
    }

    it('takes no edit anymore once the logout started', async () => {
      const storeTag = vi.fn(() => ({ tagAssignmentAdd: { success: true, errors: null } }))

      mockTagAssignmentAddMutation(storeTag)
      mountAssignment(['vip'])

      startLogout()

      expect(api.addTag('billing')).toBe(false)
      api.removeTag('vip')
      await flushPromises()

      expect(readTags()).toEqual(['vip'])
      expect(storeTag).not.toHaveBeenCalled()
    })

    const queueTwoRemovals = async () => {
      let answerVipRemoval!: () => void

      mockTagAssignmentRemoveMutation(
        () =>
          new Promise((resolve) => {
            answerVipRemoval = () =>
              resolve({ tagAssignmentRemove: { success: true, errors: null } })
          }),
      )
      mountAssignment(['vip', 'billing'])

      api.removeTag('vip')
      await waitForTagAssignmentRemoveMutationCalls()
      api.removeTag('billing')

      return () => answerVipRemoval()
    }

    it('sends none of the edits still queued, also not after a new login', async () => {
      const answerVipRemoval = await queueTwoRemovals()

      logOut()

      answerVipRemoval()
      await flushPromises()

      expect(await waitForTagAssignmentRemoveMutationCalls()).toHaveLength(1)
    })

    it('leaves the cache alone when an edit fails after the logout', async () => {
      let failRemoval!: (error: Error) => void

      mockTagAssignmentRemoveMutation(
        () =>
          new Promise((_resolve, reject) => {
            failRemoval = reject
          }),
      )
      mountAssignment(['vip', 'billing'])

      api.removeTag('vip')
      await waitForTagAssignmentRemoveMutationCalls()

      logOut()
      // What the next session loaded for the record.
      writeTags(['billing'])

      failRemoval(new Error('Not authenticated'))
      await flushPromises()

      expect(readTags()).toEqual(['billing'])
    })
  })

  it('opens the field for a new tag and closes it again', async () => {
    mountAssignment([])

    expect(api.isNewTagVisible.value).toBe(false)

    await api.showNewTag()

    expect(api.isNewTagVisible.value).toBe(true)

    api.hideNewTag()

    expect(api.isNewTagVisible.value).toBe(false)
  })
})
