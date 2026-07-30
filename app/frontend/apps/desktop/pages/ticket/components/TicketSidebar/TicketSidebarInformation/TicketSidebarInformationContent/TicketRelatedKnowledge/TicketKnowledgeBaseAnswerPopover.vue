<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonLabel from '#shared/components/CommonLabel/CommonLabel.vue'
import type { KnowledgeBaseAnswerTranslationFragment } from '#shared/graphql/types.ts'

import KnowledgeBaseAnswerIcon from '#desktop/components/KnowledgeBaseAnswerIcon/KnowledgeBaseAnswerIcon.vue'

import KnowledgeBaseAnswerAttributes from './KnowledgeBaseAnswerAttributes.vue'

interface Props {
  translation: KnowledgeBaseAnswerTranslationFragment
}

defineProps<Props>()
</script>

<template>
  <section data-type="popover" class="@container space-y-3 p-3">
    <div class="flex items-center gap-1.25">
      <KnowledgeBaseAnswerIcon show-tooltip :visibility="translation.visibility" size="tiny" />
      <CommonLabel
        v-tooltip.supportive="translation.title"
        size="large"
        tag="h3"
        class="line-clamp-1! grow"
      >
        {{ translation.title }}
      </CommonLabel>
    </div>

    <CommonLabel
      v-if="translation.content.bodyExcerpt"
      tag="p"
      class="text-stone-200! dark:text-neutral-500!"
    >
      {{ translation.content.bodyExcerpt }}
    </CommonLabel>

    <KnowledgeBaseAnswerAttributes :translation="translation" />
  </section>
</template>
