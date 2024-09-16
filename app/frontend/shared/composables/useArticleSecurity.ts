// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { computed, type Ref } from 'vue'

import {
  NotificationTypes,
  useNotifications,
} from '#shared/components/CommonNotifications/index.ts'
import type { TicketArticle } from '#shared/entities/ticket/types.ts'
import { translateArticleSecurity } from '#shared/entities/ticket-article/composables/translateArticleSecurity.ts'
import { useTicketArticleRetrySecurityProcessMutation } from '#shared/entities/ticket-article/graphql/mutations/ticketArticleRetrySecurityProcess.api.ts'
import { i18n } from '#shared/i18n/index.ts'
import { MutationHandler } from '#shared/server/apollo/handler/index.ts'

export const useArticleSecurity = (article: Ref<TicketArticle>) => {
  const { notify } = useNotifications()

  const signingSuccess = computed(
    () => article.value?.securityState?.signingSuccess,
  )

  const signingMessage = computed(
    () => article.value?.securityState?.signingMessage,
  )

  const encryptionSuccess = computed(
    () => article.value?.securityState?.encryptionSuccess,
  )

  const encryptionMessage = computed(
    () => article.value?.securityState?.encryptionMessage,
  )

  const isEncrypted = computed(
    () =>
      article.value.securityState?.encryptionSuccess ||
      (article.value.securityState?.encryptionSuccess === false &&
        article.value.securityState?.encryptionMessage),
  )

  const isSigned = computed(
    () =>
      article.value.securityState?.signingSuccess ||
      (article.value.securityState?.signingSuccess === false &&
        article.value.securityState?.signingMessage),
  )

  const hasSecurityAttribute = computed(
    () => article.value.securityState && (isEncrypted.value || isSigned.value),
  )

  const hasError = computed(() => {
    if (!article.value.securityState) return false

    if (
      article?.value.securityState?.signingSuccess === false &&
      article?.value.securityState?.signingMessage
    )
      return true

    return !!(
      article?.value.securityState?.encryptionSuccess === false &&
      article?.value.securityState?.encryptionMessage
    )
  })

  const retrySecurityProcess = async () => {
    const retryMutation = new MutationHandler(
      useTicketArticleRetrySecurityProcessMutation(() => ({
        variables: {
          articleId: article.value.id,
        },
      })),
    )

    const result = await retryMutation.send()
    const security = result?.ticketArticleRetrySecurityProcess?.retryResult

    if (!security) {
      return notify({
        id: 'retry-security-error',
        type: NotificationTypes.Error,
        message: __('The retried security process failed!'),
        timeout: 2000,
      })
    }

    if (security.type !== article.value?.securityState?.type) {
      // shouldn't be possible, we only support S/MIME
      return notify({
        id: 'security-mechanism-error',
        type: NotificationTypes.Error,
        message: __('Article uses different security mechanism.'),
        timeout: 2000,
      })
    }

    if (security.signingSuccess) {
      notify({
        id: 'signature-verified',
        type: NotificationTypes.Success,
        message: __('The signature was successfully verified.'),
      })
    } else if (security.signingMessage) {
      notify({
        id: 'signature-verification-failed',
        type: NotificationTypes.Error,
        message: __('Signature verification failed! %s'),
        messagePlaceholder: [i18n.t(security.signingMessage)],
        timeout: 2000,
      })
    }

    if (security.encryptionSuccess) {
      notify({
        id: 'decryption-success',
        type: NotificationTypes.Success,
        message: __('Decryption was successful.'),
      })
    } else if (security.encryptionMessage) {
      notify({
        id: 'decryption-failed',
        type: NotificationTypes.Error,
        message: __('Decryption failed! %s'),
        messagePlaceholder: [i18n.t(security.encryptionMessage)],
        timeout: 2000,
      })
    }
  }

  const typeLabel = computed(() => {
    if (!article.value?.securityState?.type) return

    return translateArticleSecurity(article.value?.securityState?.type)
  })

  return {
    hasError,
    signingSuccess,
    signingMessage,
    encryptionSuccess,
    encryptionMessage,
    isEncrypted,
    isSigned,
    hasSecurityAttribute,
    typeLabel,
    signingIcon: computed(() =>
      signingSuccess.value ? 'signing-success' : 'signing-fail',
    ),
    encryptionIcon: computed(() =>
      encryptionSuccess.value ? 'encryption-success' : 'encryption-fail',
    ),
    signedStatusMessage: computed(() =>
      signingSuccess.value ? __('Signed') : __('Sign error'),
    ),
    encryptedStatusMessage: computed(() =>
      encryptionSuccess.value ? __('Encrypted') : __('Encryption error'),
    ),
    retrySecurityProcess,
  }
}
