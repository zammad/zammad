<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonSectionPopup from '@mobile/components/CommonSectionPopup/CommonSectionPopup.vue'
import {
  NotificationTypes,
  useNotifications,
} from '@shared/components/CommonNotifications'
import { useTicketArticleRetrySecurityProcessMutation } from '@shared/entities/ticket-article/graphql/mutations/ticketArticleRetrySecurityProcess.api'
import type { TicketArticleSecurityState } from '@shared/graphql/types'
import { i18n } from '@shared/i18n'
import { MutationHandler } from '@shared/server/apollo/handler'
import { computed, ref } from 'vue'

export interface Props {
  articleId: string
  security: TicketArticleSecurityState
  successClass?: string
}

const props = defineProps<Props>()

const securityIcon = computed(() => {
  const { signingSuccess } = props.security
  if (signingSuccess === false) return 'mobile-not-signed'
  return 'mobile-unlock'
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
      type: NotificationTypes.Error,
      message: __('The retried security process failed!'),
      timeout: 2000,
    })
    return
  }
  if (security.type !== props.security.type) {
    // shouldn't be possible, we only support S/MIME
    notify({
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
      type: NotificationTypes.Success,
      message: __('The signature was successfully verified.'),
    })
  } else if (security.signingMessage) {
    notify({
      type: NotificationTypes.Error,
      message: __('Signature verification failed! %s'),
      messagePlaceholder: [i18n.t(security.signingMessage)],
      timeout: 2000,
    })
    hidePopup = false
  }

  if (security.encryptionSuccess) {
    notify({
      type: NotificationTypes.Success,
      message: __('Decryption was successful.'),
    })
  } else if (security.encryptionMessage) {
    notify({
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
    class="inline-flex h-6 grow items-center gap-1 rounded-lg bg-yellow px-2 py-1 text-xs font-bold text-black"
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
    class="inline-flex h-6 grow items-center gap-1 rounded-lg px-2 py-1"
    @click.prevent="showPopup = !showPopup"
    @keydown.space.prevent="showPopup = !showPopup"
  >
    <CommonIcon
      v-if="security.encryptionSuccess"
      name="mobile-lock"
      size="xs"
      :label="$t('Encrypted')"
    />
    <CommonIcon
      v-if="security.signingSuccess"
      name="mobile-signed"
      size="xs"
      :label="$t('Signed')"
    />
  </button>
  <CommonSectionPopup v-model:state="showPopup" :items="popupItems">
    <template #header>
      <div
        class="flex flex-col items-center gap-2 border-b border-b-white/10 p-4"
      >
        <div
          v-if="hasError"
          class="flex w-full items-center justify-center gap-1 text-yellow"
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
          {{ $t('Sign') }}: {{ $t(security.signingMessage) }}
        </div>
        <div
          v-if="security.encryptionMessage"
          :class="{
            'text-orange': !hasError && security.encryptionSuccess === false,
          }"
        >
          {{ $t('Encryption') }}: {{ $t(security.encryptionMessage) }}
        </div>
      </div>
    </template>
  </CommonSectionPopup>
</template>
