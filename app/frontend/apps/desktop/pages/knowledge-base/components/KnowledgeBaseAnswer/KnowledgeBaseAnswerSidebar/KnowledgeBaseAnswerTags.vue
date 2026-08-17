<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->
<script lang="ts" setup>
import { computed } from 'vue'

import CommonLabel from '#shared/components/CommonLabel/CommonLabel.vue'
import CommonLink from '#shared/components/CommonLink/CommonLink.vue'

import CommonSectionCollapse from '#desktop/components/CommonSectionCollapse/CommonSectionCollapse.vue'
import { tagSearchRoute } from '#desktop/entities/tags/utils/routeLocation.ts'

import type { KnowledgeBaseAnswerHeader } from '../../../types.ts'

interface Props {
  answer: KnowledgeBaseAnswerHeader
}

const props = defineProps<Props>()

const tags = computed(
  () => props.answer.tags?.map((tag) => ({ label: tag, link: tagSearchRoute(tag) })) ?? [],
)
</script>

<template>
  <CommonSectionCollapse id="knowledge-base-tags" :title="__('Tags')">
    <template #default="{ headerId }">
      <ul
        v-if="tags.length"
        :aria-labelledby="headerId"
        class="flex w-full flex-col rounded-lg bg-blue-200 px-2.5 dark:bg-gray-700"
      >
        <li v-for="tag in tags" :key="tag.label" class="flex items-center gap-1.5 py-2.5">
          <CommonLabel class="grow" prefix-icon="tag">
            <CommonLink class="line-clamp-1" :link="tag.link" size="medium">
              {{ tag.label }}
            </CommonLink>
          </CommonLabel>
        </li>
      </ul>

      <CommonLabel v-else size="small">
        {{ $t('No tags added yet.') }}
      </CommonLabel>
    </template>
  </CommonSectionCollapse>
</template>
