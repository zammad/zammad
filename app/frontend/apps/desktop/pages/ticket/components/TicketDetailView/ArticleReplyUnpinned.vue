<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { nextTick, onMounted, ref } from 'vue'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'

interface Props {
  hasInternalArticle?: boolean
}

defineProps<Props>()

defineEmits<{
  'discard-form': []
  'toggle-pin': []
}>()

const articlePanel = ref<HTMLElement>()

onMounted(() => {
  nextTick(() => {
    // NB: Give editor a chance to initialize its height.
    setTimeout(() => {
      articlePanel.value?.scrollIntoView?.(true)
    }, 300)
  })
})

defineExpose({ articlePanel })
</script>

<template>
  <div ref="articlePanel" class="relative mx-auto flex h-fit w-full max-w-6xl flex-col px-12 py-4">
    <div
      class="flex grow flex-col"
      data-test-id="article-reply-stripes-panel"
      :class="{
        'bg-stripes relative z-0 rounded-xl outline-1 outline-blue-700 before:rounded-2xl':
          hasInternalArticle,
      }"
    >
      <div
        class="isolate flex grow flex-col rounded-xl border border-neutral-300 bg-neutral-50 dark:border-gray-900 dark:bg-gray-500"
      >
        <div class="flex h-10 items-center p-3">
          <CommonLabel
            id="article-reply-form-title"
            class="text-stone-200 ltr:mr-auto rtl:ml-auto dark:text-neutral-500"
            tag="h2"
            size="small"
          >
            {{ $t('Reply') }}
          </CommonLabel>
          <CommonButton
            v-tooltip="$t('Discard unsaved reply')"
            class="text-red-500 ltr:mr-2 rtl:ml-2"
            variant="none"
            icon="trash"
            @click="$emit('discard-form')"
          />
          <CommonButton
            v-tooltip="$t('Pin this panel')"
            icon="pin-angle"
            variant="neutral"
            size="small"
            @click="$emit('toggle-pin')"
          />
        </div>
        <div id="ticketArticleReplyForm" class="grow px-3 pb-3" />
      </div>
    </div>
  </div>
</template>
