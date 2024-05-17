<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, ref } from 'vue'

import {
  NotificationTypes,
  useNotifications,
} from '#shared/components/CommonNotifications/index.ts'
import { useTicketArticleRetryMediaDownloadMutation } from '#shared/entities/ticket-article/graphql/mutations/ticketArticleRetryMediaDownload.api.ts'
import { MutationHandler } from '#shared/server/apollo/handler/index.ts'

import CommonSectionPopup from '#mobile/components/CommonSectionPopup/CommonSectionPopup.vue'

export interface Props {
  articleId: string
  mediaError: boolean
}

const props = defineProps<Props>()

const showPopup = ref(false)

const retryMutation = new MutationHandler(
  useTicketArticleRetryMediaDownloadMutation(() => ({
    variables: {
      articleId: props.articleId,
    },
  })),
)

const { notify } = useNotifications()

const loading = ref(false)

const tryAgain = async () => {
  loading.value = true
  const result = await retryMutation.send()

  if (result?.ticketArticleRetryMediaDownload?.success) {
    notify({
      id: 'media-download-success',
      type: NotificationTypes.Success,
      message: __('Media download was successful.'),
    })

    showPopup.value = false
  } else {
    notify({
      id: 'media-download-failed',
      type: NotificationTypes.Error,
      message: __('Media download failed. Please try again later.'),
    })
  }

  loading.value = false
}

const popupItems = computed(() =>
  props.mediaError && !loading.value
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
    v-if="props.mediaError"
    type="button"
    class="bg-yellow inline-flex h-7 grow items-center gap-1 rounded-lg px-2 py-1 text-xs font-bold text-black"
    @click.prevent="showPopup = !showPopup"
    @keydown.space.prevent="showPopup = !showPopup"
  >
    <CommonIcon name="update" decorative size="xs" />
    {{ $t('Media Download Error') }}
  </button>
  <CommonSectionPopup v-model:state="showPopup" :messages="popupItems">
    <template #header>
      <div
        class="flex flex-col items-center gap-2 border-b border-b-white/10 p-4"
      >
        <div
          v-if="props.mediaError"
          class="text-yellow flex w-full items-center justify-center gap-1"
        >
          <CommonIcon name="update" size="tiny" />
          {{ $t('Media Download Error') }}
        </div>
        <div
          v-if="loading"
          class="flex w-full items-center justify-center gap-1"
        >
          <CommonIcon name="loading" animation="spin" />
        </div>
      </div>
    </template>
  </CommonSectionPopup>
</template>
