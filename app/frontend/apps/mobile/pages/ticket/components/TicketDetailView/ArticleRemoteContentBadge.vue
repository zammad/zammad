<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, ref } from 'vue'

import CommonSectionPopup from '#mobile/components/CommonSectionPopup/CommonSectionPopup.vue'

export interface Props {
  originalFormattingUrl?: string
}

const props = defineProps<Props>()

const showPopup = ref(false)

const popupItems = computed(() =>
  props.originalFormattingUrl
    ? [
        {
          type: 'link' as const,
          label: __('Original Formatting'),
          link: props.originalFormattingUrl,
          attributes: {
            'rest-api': true,
            target: '_blank',
          },
        },
      ]
    : [],
)
</script>

<template>
  <button
    v-bind="$attrs"
    type="button"
    class="inline-flex h-7 grow items-center gap-1 rounded-lg px-2 py-1 text-xs font-bold"
    @click.prevent="showPopup = !showPopup"
    @keydown.space.prevent="showPopup = !showPopup"
  >
    <CommonIcon name="warning" decorative size="xs" />
    {{ $t('Blocked Content') }}
  </button>
  <CommonSectionPopup v-model:state="showPopup" :messages="popupItems">
    <template #header>
      <div
        class="flex flex-col items-center gap-2 border-b border-b-white/10 p-4"
      >
        <div class="flex w-full items-center justify-center gap-1">
          <CommonIcon name="warning" size="tiny" />
          {{ $t('Blocked Content') }}
        </div>
        <div>
          {{
            $t(
              'This message contains images or other content hosted by an external source. It was blocked, but you can download the original formatting here.',
            )
          }}
        </div>
      </div>
    </template>
  </CommonSectionPopup>
</template>
