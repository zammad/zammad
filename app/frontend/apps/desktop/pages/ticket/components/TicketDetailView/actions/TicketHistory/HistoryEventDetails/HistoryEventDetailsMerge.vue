<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonTranslateRenderer from '#shared/components/CommonTranslateRenderer/CommonTranslateRenderer.vue'

import type { EventActionOutput } from '../types.ts'

interface Props {
  event: EventActionOutput
}

const { event } = defineProps<Props>()

const actionName2Source: Record<string, string> = {
  'received-merge': __('Merged %s into this ticket'),
  'merged-into': __('Merged this ticket into %s'),
}
</script>

<template>
  <span>
    <CommonTranslateRenderer
      class="text-sm leading-snug text-gray-100 dark:text-neutral-400"
      :source="actionName2Source[event.actionName]"
      :placeholders="[
        {
          type: 'link',
          props: {
            link: event.link,
            size: 'medium',
            class: 'text-blue-800 hover:underline',
          },
          content: event.details || '',
        },
      ]"
    />
  </span>
</template>
