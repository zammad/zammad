<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonTranslateRenderer from '#shared/components/CommonTranslateRenderer/CommonTranslateRenderer.vue'
import { getAiAssistantTextToolsLoadingBannerClasses } from '#shared/components/Form/fields/FieldEditor/features/ai-assistant-text-tools/AiAssistantLoadingBanner/initializeAiAssistantTextToolsLoadingBannerClasses.ts'
import { useAppName } from '#shared/composables/useAppName.ts'

import type { Editor } from '@tiptap/core'

defineProps<{
  editor?: Editor
}>()

const { icon, label, button } = getAiAssistantTextToolsLoadingBannerClasses()

const appName = useAppName()
</script>

<template>
  <div
    class="ai-stripe animate-ai-stripe relative flex items-center gap-1 px-4 py-3 before:absolute before:top-0 before:left-0"
  >
    <CommonIcon class="shrink-0" :class="icon" size="tiny" name="smart-assist" />

    <CommonTranslateRenderer
      v-if="appName === 'desktop'"
      class="truncate text-sm"
      :source="__('%s is generating text…')"
      :placeholders="[
        {
          type: 'label',
          props: {
            class: label,
          },
          content: $t('Writing Assistant'),
        },
      ]"
    />
    <CommonLabel v-else>{{ $t('Generating text…') }}</CommonLabel>

    <button
      class="text-sm ltr:ml-auto rtl:mr-auto"
      :class="button"
      @click="editor?.emit('cancel-ai-assistant-text-tools-updates')"
    >
      {{ $t('Cancel') }}
    </button>
  </div>
</template>
