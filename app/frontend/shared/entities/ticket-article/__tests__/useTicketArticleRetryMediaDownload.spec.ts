// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { ref } from 'vue'

import { NotificationTypes } from '#shared/components/CommonNotifications/types.ts'
import { useNotifications } from '#shared/components/CommonNotifications/useNotifications.ts'
import { convertToGraphQLId } from '#shared/graphql/utils.ts'

import { useTicketArticleRetryMediaDownload } from '../composables/useTicketArticleRetryMediaDownload.ts'
import {
  mockTicketArticleRetryMediaDownloadMutation,
  waitForTicketArticleRetryMediaDownloadMutationCalls,
} from '../graphql/mutations/ticketArticleRetryMediaDownload.mocks.ts'

describe('useTicketArticleRetryMediaDownload', () => {
  const testArticleId = ref(convertToGraphQLId('Ticket::Article', 1))

  const { loading, tryAgain } =
    useTicketArticleRetryMediaDownload(testArticleId)

  describe('tryAgain', () => {
    it('resolves on success', async () => {
      mockTicketArticleRetryMediaDownloadMutation({
        ticketArticleRetryMediaDownload: {
          success: true,
        },
      })

      expect(tryAgain()).resolves.toBeUndefined()

      const calls = await waitForTicketArticleRetryMediaDownloadMutationCalls()

      expect(calls.at(-1)?.variables).toEqual({
        articleId: testArticleId.value,
      })
    })

    it('rejects on error', async () => {
      mockTicketArticleRetryMediaDownloadMutation({
        ticketArticleRetryMediaDownload: {
          success: false,
          errors: [
            {
              message: 'Something went wrong',
            },
          ],
        },
      })

      expect(tryAgain()).rejects.toThrow()

      const calls = await waitForTicketArticleRetryMediaDownloadMutationCalls()

      expect(calls.at(-1)?.variables).toEqual({
        articleId: testArticleId.value,
      })
    })

    it('shows a notification on success', async () => {
      mockTicketArticleRetryMediaDownloadMutation({
        ticketArticleRetryMediaDownload: {
          success: true,
        },
      })

      await tryAgain()

      const { notify } = useNotifications()

      expect(notify).toHaveBeenCalledWith({
        id: 'media-download-success',
        message: 'Media download was successful.',
        type: NotificationTypes.Success,
      })
    })

    it('shows a notification on error', async () => {
      mockTicketArticleRetryMediaDownloadMutation({
        ticketArticleRetryMediaDownload: {
          success: false,
          errors: [
            {
              message: 'Something went wrong',
            },
          ],
        },
      })

      try {
        await tryAgain()
      } catch {
        // no-op
      }

      const { notify } = useNotifications()

      expect(notify).toHaveBeenCalledWith({
        id: 'media-download-failed',
        message: 'Media download failed. Please try again later.',
        type: NotificationTypes.Error,
      })
    })
  })

  describe('loading', () => {
    it('returns correct request state on success', async () => {
      expect(loading.value).toBe(false)

      mockTicketArticleRetryMediaDownloadMutation({
        ticketArticleRetryMediaDownload: {
          success: true,
        },
      })

      const promise = tryAgain()

      expect(loading.value).toBe(true)

      await promise

      expect(loading.value).toBe(false)
    })

    it('returns correct request state on error', async () => {
      expect(loading.value).toBe(false)

      mockTicketArticleRetryMediaDownloadMutation({
        ticketArticleRetryMediaDownload: {
          success: false,
          errors: [
            {
              message: 'Something went wrong',
            },
          ],
        },
      })

      const promise = tryAgain()

      expect(loading.value).toBe(true)

      try {
        await promise
      } catch {
        // no-op
      }

      expect(loading.value).toBe(false)
    })
  })
})
