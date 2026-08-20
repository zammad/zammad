<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import CommonDateTime from '#shared/components/CommonDateTime/CommonDateTime.vue'
import { userDisplayName } from '#shared/entities/user/utils/getUserDisplayName.ts'

import CommonObjectAttribute from '#desktop/components/CommonObjectAttribute/CommonObjectAttribute.vue'
import CommonObjectAttributeContainer from '#desktop/components/CommonObjectAttribute/CommonObjectAttributeContainer.vue'
import { visibilityMeta } from '#desktop/components/KnowledgeBaseAnswerIcon/visibilityMeta.ts'

import KnowledgeBaseAnswerLinkedTickets from './KnowledgeBaseAnswerLinkedTickets.vue'
import KnowledgeBaseAnswerTags from './KnowledgeBaseAnswerTags.vue'

import type { KnowledgeBaseAnswerHeader } from '../../../types.ts'

const props = defineProps<{ answer: KnowledgeBaseAnswerHeader }>()

const editedByLabel = computed(() => {
  const editedBy = props.answer?.editedBy

  return editedBy ? userDisplayName(editedBy) : undefined
})
</script>

<template>
  <CommonObjectAttributeContainer class="p-3">
    <CommonObjectAttribute :label="__('Visibility')">
      {{ $t(visibilityMeta[answer.visibility].label) }}
    </CommonObjectAttribute>

    <CommonObjectAttribute v-if="answer.internalAt" :label="__('Internally published')">
      <CommonDateTime :date-time="answer.internalAt" type="relative" />
    </CommonObjectAttribute>

    <CommonObjectAttribute v-if="answer.publishedAt" :label="__('Published')">
      <CommonDateTime :date-time="answer.publishedAt" type="relative" />
    </CommonObjectAttribute>

    <CommonObjectAttribute v-if="answer.archivedAt" :label="__('Archived')">
      <CommonDateTime :date-time="answer.archivedAt" type="relative" />
    </CommonObjectAttribute>

    <CommonObjectAttribute v-if="answer.editedAt" :label="__('Last updated')">
      <CommonDateTime :date-time="answer.editedAt" type="relative" />
    </CommonObjectAttribute>

    <CommonObjectAttribute v-if="editedByLabel" :label="__('Updated by')">
      <span v-tooltip.supportive="editedByLabel" class="line-clamp-1">
        {{ editedByLabel }}
      </span>
    </CommonObjectAttribute>
  </CommonObjectAttributeContainer>

  <KnowledgeBaseAnswerTags :answer="answer" class="p-3" />

  <KnowledgeBaseAnswerLinkedTickets :answer="answer" class="p-3" />
</template>
