<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonTranslateRenderer from '#shared/components/CommonTranslateRenderer/CommonTranslateRenderer.vue'

import type { EventActionOutput } from '../types.ts'

interface Props {
  event: EventActionOutput
}

const { event } = defineProps<Props>()
</script>

<template>
  <span>
    <CommonTranslateRenderer
      class="text-sm leading-snug text-gray-100 dark:text-neutral-400"
      :source="__('Email sent to %s')"
      :placeholders="[
        {
          type: 'label',
          props: {
            size: 'medium',
            class:
              'cursor-text rounded bg-neutral-200 px-0.5 font-mono text-black dark:bg-gray-400 dark:text-white',
          },
          content: event.details || '',
        },
      ]"
    />
  </span>
</template>
