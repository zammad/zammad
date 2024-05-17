<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, ref } from 'vue'

import {
  NotificationTypes,
  useNotifications,
} from '#shared/components/CommonNotifications/index.ts'
import { useTicketArticleRetrySecurityProcessMutation } from '#shared/entities/ticket-article/graphql/mutations/ticketArticleRetrySecurityProcess.api.ts'
import type { TicketArticleSecurityState } from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n.ts'
import { MutationHandler } from '#shared/server/apollo/handler/index.ts'

import CommonSectionPopup from '#mobile/components/CommonSectionPopup/CommonSectionPopup.vue'

export interface Props {
  articleId: string
  security: TicketArticleSecurityState
  successClass?: string
}

const props = defineProps<Props>()

const securityIcon = computed(() => {
  const { signingSuccess } = props.security
  if (signingSuccess === false) return 'not-signed'
  return 'unlock'
})

const hasError = computed(() => {
  const {
    signingMessage,
    signingSuccess,
    encryptionMessage,
    encryptionSuccess,
  } = props.security
  if (signingSuccess === false && signingMessage) return true
  if (encryptionSuccess === false && encryptionMessage) return true
  return false
})

const canView = computed(() => {
  const { signingSuccess, encryptionSuccess } = props.security
  return signingSuccess === true || encryptionSuccess === true
})

const showPopup = ref(false)

const retryMutation = new MutationHandler(
  useTicketArticleRetrySecurityProcessMutation(() => ({
    variables: {
      articleId: props.articleId,
    },
  })),
)

const { notify } = useNotifications()

const tryAgain = async () => {
  const result = await retryMutation.send()
  const security = result?.ticketArticleRetrySecurityProcess?.retryResult
  if (!security) {
    notify({
      id: 'retry-security-error',
      type: NotificationTypes.Error,
      message: __('The retried security process failed!'),
      timeout: 2000,
    })
    return
  }
  if (security.type !== props.security.type) {
    // shouldn't be possible, we only support S/MIME
    notify({
      id: 'security-mechanism-error',
      type: NotificationTypes.Error,
      message: __('Article uses different security mechanism.'),
      timeout: 2000,
    })
    showPopup.value = false
    return
  }

  let hidePopup = true

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
    hidePopup = false
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
    hidePopup = false
  }

  if (hidePopup) {
    showPopup.value = false
  }
}

const popupItems = computed(() =>
  hasError.value
    ? [
        {
          type: 'button' as const,
          label: __('Try again'),
          onAction: tryAgain,
          noHideOnSelect: true,
        },
      ]
    : [],
)
</script>

<template>
  <button
    v-if="hasError"
    v-bind="$attrs"
    type="button"
    class="bg-yellow inline-flex h-7 grow items-center gap-1 rounded-lg px-2 py-1 text-xs font-bold text-black"
    @click.prevent="showPopup = !showPopup"
    @keydown.space.prevent="showPopup = !showPopup"
  >
    <CommonIcon :name="securityIcon" decorative size="xs" />
    {{ $t('Security Error') }}
  </button>
  <button
    v-else-if="canView"
    v-bind="$attrs"
    :class="successClass"
    class="inline-flex h-7 grow items-center gap-1 rounded-lg px-2 py-1"
    type="button"
    data-test-id="securityBadge"
    @click.prevent="showPopup = !showPopup"
    @keydown.space.prevent="showPopup = !showPopup"
  >
    <CommonIcon
      v-if="security.encryptionSuccess"
      name="lock"
      size="tiny"
      :label="$t('Encrypted')"
    />
    <CommonIcon
      v-if="security.signingSuccess"
      name="signed"
      size="tiny"
      :label="$t('Signed')"
    />
  </button>
  <CommonSectionPopup v-model:state="showPopup" :messages="popupItems">
    <template #header>
      <div
        class="flex flex-col items-center gap-2 border-b border-b-white/10 p-4"
      >
        <div
          v-if="hasError"
          class="text-yellow flex w-full items-center justify-center gap-1"
        >
          <CommonIcon :name="securityIcon" size="tiny" />
          {{ $t('Security Error') }}
        </div>
        <div
          v-if="security.signingMessage"
          :class="{
            'text-orange': !hasError && security.signingSuccess === false,
          }"
        >
          {{ $t('Sign:') }} {{ $t(security.signingMessage) }}
        </div>
        <div
          v-if="security.encryptionMessage"
          class="break-all"
          :class="{
            'text-orange': !hasError && security.encryptionSuccess === false,
          }"
        >
          {{ $t('Encryption:') }} {{ $t(security.encryptionMessage) }}
        </div>
        <div v-if="!security.encryptionMessage && !security.signingMessage">
          {{ $t('No security information available.') }}
        </div>
      </div>
    </template>
  </CommonSectionPopup>
</template>
