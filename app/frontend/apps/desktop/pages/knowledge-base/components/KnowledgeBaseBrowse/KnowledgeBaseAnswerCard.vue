<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { storeToRefs } from 'pinia'
import { computed } from 'vue'

import CommonBadge from '#shared/components/CommonBadge/CommonBadge.vue'
import CommonIcon from '#shared/components/CommonIcon/CommonIcon.vue'
import CommonLabel from '#shared/components/CommonLabel/CommonLabel.vue'

import KnowledgeBaseAnswerIcon from '#desktop/components/KnowledgeBaseAnswerIcon/KnowledgeBaseAnswerIcon.vue'
import { useKnowledgeBaseStore } from '#desktop/entities/knowledge-base/stores/knowledgeBase.ts'
import { knowledgeBaseAnswerRoute } from '#desktop/entities/knowledge-base/utils/routeLocation.ts'

import type { KnowledgeBaseAnswerCompact } from '../../types.ts'

const props = defineProps<KnowledgeBaseAnswerCompact>()

const { activeLocale } = storeToRefs(useKnowledgeBaseStore())

// The answer route pins the locale; without it there is no valid target yet.
const link = computed(() =>
  activeLocale.value ? knowledgeBaseAnswerRoute(activeLocale.value, props.id) : undefined,
)
</script>

<template>
  <li>
    <component
      :is="link ? 'CommonLink' : 'div'"
      :link="link"
      :internal="link ? true : undefined"
      class="flex h-12.5 w-full items-center gap-3 rounded-xl! bg-blue-200 px-3 hover:outline-1 hover:outline-blue-600 dark:bg-gray-500 hover:dark:outline-blue-900"
    >
      <KnowledgeBaseAnswerIcon :visibility="visibility" size="small" />
      <CommonLabel size="medium" tag="h3" class="line-clamp-1! grow text-black! dark:text-white!">
        {{ title }}
      </CommonLabel>
      <CommonBadge
        v-if="translationMissing"
        v-tooltip="$t('No translation for this locale available')"
        variant="warning"
        size="xs"
        rounded
        class="flex items-center justify-center p-1!"
      >
        <CommonIcon name="translate" size="xs" decorative />
      </CommonBadge>
    </component>
  </li>
</template>
