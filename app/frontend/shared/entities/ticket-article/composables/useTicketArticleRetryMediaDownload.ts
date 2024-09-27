// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { ref, type Ref } from 'vue'

import { NotificationTypes } from '#shared/components/CommonNotifications/types.ts'
import { useNotifications } from '#shared/components/CommonNotifications/useNotifications.ts'
import { MutationHandler } from '#shared/server/apollo/handler/index.ts'

import { useTicketArticleRetryMediaDownloadMutation } from '../graphql/mutations/ticketArticleRetryMediaDownload.api.ts'

export const useTicketArticleRetryMediaDownload = (articleId: Ref<string>) => {
  const retryMutation = new MutationHandler(
    useTicketArticleRetryMediaDownloadMutation(() => ({
      variables: {
        articleId: articleId.value,
      },
    })),
  )

  const { notify } = useNotifications()

  const loading = ref(false)

  const tryAgain = async () => {
    loading.value = true

    try {
      const result = await retryMutation.send()

      if (!result?.ticketArticleRetryMediaDownload?.success) throw new Error()

      notify({
        id: 'media-download-success',
        type: NotificationTypes.Success,
        message: __('Media download was successful.'),
      })

      return Promise.resolve()
    } catch (error) {
      notify({
        id: 'media-download-failed',
        type: NotificationTypes.Error,
        message: __('Media download failed. Please try again later.'),
      })

      return Promise.reject(error)
    } finally {
      loading.value = false
    }
  }

  return {
    loading,
    tryAgain,
  }
}
