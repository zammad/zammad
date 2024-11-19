<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonTranslateRenderer from '#shared/components/CommonTranslateRenderer/CommonTranslateRenderer.vue'
import type { RenderPlaceholder } from '#shared/components/CommonTranslateRenderer/types.ts'

import type { EventActionOutput } from '../types.ts'

interface Props {
  event: EventActionOutput
}

const { event } = defineProps<Props>()

const actionName2Source: Record<string, string> = {
  'removed-reaction': __('Removed reaction from message %s from %s'),
  'changed-reaction': __('Changed reaction on message %s from %s'),
  'changed-reaction-to': __('Changed reaction to %s on message %s from %s'),
  reacted: __('Reacted to message %s from %s'),
  'reacted-with': __('Reacted with %s to message %s from %s'),
}

const truncatedArticle: RenderPlaceholder = {
  type: 'label',
  props: {
    size: 'medium',
    class:
      'cursor-text rounded bg-neutral-200 px-0.5 font-mono text-black dark:bg-gray-400 dark:text-white',
  },
  content: event.details || '',
}

const messageCreator: RenderPlaceholder = {
  type: 'label',
  props: {
    size: 'medium',
  },
  content: event.additionalDetails || '',
}

const emoji: RenderPlaceholder = {
  type: 'label',
  props: {
    size: 'medium',
  },
  content: event.description || '',
}

const actionName2Placeholder: Record<string, RenderPlaceholder[]> = {
  'changed-reaction': [truncatedArticle, messageCreator],
  'changed-reaction-to': [emoji, truncatedArticle, messageCreator],
  reacted: [truncatedArticle, messageCreator],
  'reacted-with': [emoji, truncatedArticle, messageCreator],
  'removed-reaction': [truncatedArticle, messageCreator],
}
</script>

<template>
  <span>
    <CommonTranslateRenderer
      class="text-sm leading-snug text-gray-100 dark:text-neutral-400"
      :source="actionName2Source[event.actionName]"
      :placeholders="actionName2Placeholder[event.actionName]"
    />
  </span>
</template>
