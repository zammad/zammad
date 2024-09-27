<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, ref, toRef } from 'vue'

import { useTicketArticleRetryMediaDownload } from '#shared/entities/ticket-article/composables/useTicketArticleRetryMediaDownload.ts'

import CommonSectionPopup from '#mobile/components/CommonSectionPopup/CommonSectionPopup.vue'

export interface Props {
  articleId: string
  mediaError: boolean
}

const props = defineProps<Props>()

const showPopup = ref(false)

const { loading, tryAgain } = useTicketArticleRetryMediaDownload(
  toRef(props, 'articleId'),
)

const popupItems = computed(() =>
  props.mediaError && !loading.value
    ? [
        {
          type: 'button' as const,
          label: __('Try again'),
          onAction: async () => {
            try {
              await tryAgain()
              showPopup.value = false
            } catch {
              // no-op
            }
          },
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
