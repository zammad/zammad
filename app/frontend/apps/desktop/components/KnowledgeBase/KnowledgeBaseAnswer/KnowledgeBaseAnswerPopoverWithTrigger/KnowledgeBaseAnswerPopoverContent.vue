<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import QueryHandler from '#shared/server/apollo/handler/QueryHandler.ts'

import KnowledgeBaseAnswerPopover from '#desktop/components/KnowledgeBase/KnowledgeBaseAnswer/KnowledgeBaseAnswerPopover.vue'

import { useKnowledgeBaseAnswerInfoForPopoverQuery } from './graphql/queries/knowledgeBaseAnswerInfoForPopover.api.ts'
import KnowledgeBaseAnswerPopoverSkeleton from './skeleton/KnowledgeBaseAnswerPopoverSkeleton.vue'

interface Props {
  answerId: string
  /** Locale of the translation the trigger is showing, so the popover describes that one. */
  locale?: string
}

const props = defineProps<Props>()

// Fired on mount, and this component is only mounted while the popover is open (CommonPopover
//   renders its slot behind `v-if`), which is what makes the loading lazy - a list of ten items
//   fetches nothing until one of them is actually opened.
const answerQuery = new QueryHandler(
  useKnowledgeBaseAnswerInfoForPopoverQuery(
    () => ({ answerId: props.answerId, locale: props.locale }),
    () => ({ enabled: !!props.answerId, fetchPolicy: 'cache-and-network' }),
  ),
)

const result = answerQuery.result()

const translation = computed(() => result.value?.knowledgeBaseAnswer.translation)

const loading = answerQuery.loadingWithoutCachedResult()
</script>

<!--
  The wrapper is load-bearing: KnowledgeBaseAnswerPopoverWithTrigger passes the popover's `id` down
    to this component, and the skeleton below is a conditional root (a fragment), which cannot
    inherit an attribute. Both the skeleton and KnowledgeBaseAnswerPopover carry their own padding.
-->
<template>
  <div>
    <KnowledgeBaseAnswerPopoverSkeleton :loading="loading">
      <!-- Null only for an answer with no translation at all, which the list it was opened from
           cannot have produced - guarded rather than asserted all the same. -->
      <KnowledgeBaseAnswerPopover v-if="translation" :translation="translation" />
    </KnowledgeBaseAnswerPopoverSkeleton>
  </div>
</template>
