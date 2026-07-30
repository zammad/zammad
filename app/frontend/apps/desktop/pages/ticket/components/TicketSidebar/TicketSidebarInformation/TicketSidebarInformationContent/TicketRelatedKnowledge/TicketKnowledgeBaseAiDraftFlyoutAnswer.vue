<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { prepareLegacyAppLinkNavigation } from '#desktop/components/BetaUi/utils/legacyAppLink.ts'
import KnowledgeBaseAnswerIcon from '#desktop/components/KnowledgeBaseAnswerIcon/KnowledgeBaseAnswerIcon.vue'

import KnowledgeBaseAnswerAttributes from './KnowledgeBaseAnswerAttributes.vue'
import { getKnowledgeBaseAnswerLink } from './utils/knowledgeBaseAnswerLink.ts'

import type { RelatedAnswer } from './types.ts'

interface Props {
  answer: RelatedAnswer
}

defineProps<Props>()
</script>

<template>
  <li class="space-y-1.5 py-2.5 first:pt-0 last:pb-0">
    <div class="flex items-center gap-1.5">
      <KnowledgeBaseAnswerIcon
        show-tooltip
        :visibility="answer.translation.visibility"
        size="tiny"
      />

      <CommonLink
        :link="getKnowledgeBaseAnswerLink(answer.translation)"
        external
        open-in-new-tab
        size="medium"
        class="flex grow items-center gap-1"
        @click="prepareLegacyAppLinkNavigation()"
        @auxclick="prepareLegacyAppLinkNavigation()"
      >
        <span v-tooltip="answer.translation.title" class="line-clamp-1!">
          {{ answer.translation.title }}
        </span>
        <CommonIcon
          v-tooltip="$t('Open in new tab')"
          size="tiny"
          name="box-arrow-in-up-right"
          class="shrink-0"
        />
      </CommonLink>

      <!-- :TODO will be only shown to a user who is admin and has permission to activate AI feature, upcoming story-->
      <CommonLabel
        v-tooltip.supportive="$t('Relevance score')"
        size="small"
        class="shrink-0 text-stone-200! dark:text-neutral-500!"
      >
        {{ `${answer.score}%` }}
      </CommonLabel>
    </div>

    <CommonLabel
      v-if="answer.translation.content.bodyExcerpt"
      class="text-stone-200! dark:text-neutral-500!"
    >
      {{ answer.translation.content.bodyExcerpt }}
    </CommonLabel>

    <KnowledgeBaseAnswerAttributes :translation="answer.translation" />
  </li>
</template>
