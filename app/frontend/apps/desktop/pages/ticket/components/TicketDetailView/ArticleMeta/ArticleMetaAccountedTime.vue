<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import { useTicketAccountedTime } from '#shared/entities/ticket/composables/useTicketAccountedTime.ts'
import type { TicketArticle } from '#shared/entities/ticket/types.ts'
import { cleanupMarkup, markup } from '#shared/utils/markup.ts'

interface Props {
  context: {
    article: TicketArticle
  }
}

const props = defineProps<Props>()

const { formatAccountedTime, formatAccountedTimeType } = useTicketAccountedTime()

const accountedTime = computed(() => formatAccountedTime(props.context.article.timeUnit))

const activityTypeSentence = computed(() => formatAccountedTimeType(props.context.article))
</script>

<template>
  <CommonLabel class="min-w-0 text-black! dark:text-white!">
    <span class="shrink-0">{{ accountedTime }}</span>
    <!-- The activity type is admin defined and can be long, so keep the sentence inside the row. -->
    <!-- The markup helper escapes the sentence before it turns the markers into tags. -->
    <!-- eslint-disable vue/no-v-html -->
    <span
      v-if="activityTypeSentence"
      v-tooltip.truncate.supportive="cleanupMarkup(activityTypeSentence)"
      class="min-w-0 truncate text-stone-200! *:font-normal *:text-black dark:text-neutral-500! *:dark:text-white"
      v-html="markup(activityTypeSentence)"
    />
  </CommonLabel>
</template>
