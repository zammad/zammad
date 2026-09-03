<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import CommonDateTime from '#shared/components/CommonDateTime/CommonDateTime.vue'
import { userDisplayName } from '#shared/entities/user/utils/getUserDisplayName.ts'
import { EnumKnowledgeBaseVisibility } from '#shared/graphql/types.ts'

import CommonObjectAttribute from '#desktop/components/CommonObjectAttribute/CommonObjectAttribute.vue'
import CommonObjectAttributeContainer from '#desktop/components/CommonObjectAttribute/CommonObjectAttributeContainer.vue'
import { visibilityMeta } from '#desktop/components/KnowledgeBaseAnswerIcon/visibilityMeta.ts'
import { useKnowledgeBaseAnswerReachedDates } from '#desktop/entities/knowledge-base/composables/useKnowledgeBaseAnswerReachedDates.ts'

import KnowledgeBaseAnswerLinkedTickets from './KnowledgeBaseAnswerLinkedTickets.vue'
import KnowledgeBaseAnswerScheduledVisibility from './KnowledgeBaseAnswerScheduledVisibility.vue'
import KnowledgeBaseAnswerTags from './KnowledgeBaseAnswerTags.vue'

import type { KnowledgeBaseAnswerHeader } from '../../../types.ts'

const props = defineProps<{ answer: KnowledgeBaseAnswerHeader }>()

// The dates the answer has reached, which is what these rows are about. One still ahead is a
//   scheduled change, and it has a section of its own below - a reader is told what the answer is,
//   never what it is going to become.
const { reachedDates } = useKnowledgeBaseAnswerReachedDates(() => props.answer)

const editedByLabel = computed(() => {
  const editedBy = props.answer?.translation?.editedBy

  return editedBy ? userDisplayName(editedBy) : undefined
})
</script>

<template>
  <CommonObjectAttributeContainer class="p-3">
    <CommonObjectAttribute :label="__('Visibility')">
      {{ $t(visibilityMeta[answer.visibility].label) }}
    </CommonObjectAttribute>

    <CommonObjectAttribute
      v-if="reachedDates.internalAt"
      :label="visibilityMeta[EnumKnowledgeBaseVisibility.Internal].timestampLabel"
    >
      <CommonDateTime :date-time="reachedDates.internalAt" type="relative" />
    </CommonObjectAttribute>

    <CommonObjectAttribute
      v-if="reachedDates.publishedAt"
      :label="visibilityMeta[EnumKnowledgeBaseVisibility.Published].timestampLabel"
    >
      <CommonDateTime :date-time="reachedDates.publishedAt" type="relative" />
    </CommonObjectAttribute>

    <CommonObjectAttribute
      v-if="reachedDates.archivedAt"
      :label="visibilityMeta[EnumKnowledgeBaseVisibility.Archived].timestampLabel"
    >
      <CommonDateTime :date-time="reachedDates.archivedAt" type="relative" />
    </CommonObjectAttribute>

    <CommonObjectAttribute v-if="answer.translation?.editedAt" :label="__('Last updated')">
      <CommonDateTime :date-time="answer.translation!.editedAt" type="relative" />
    </CommonObjectAttribute>

    <CommonObjectAttribute v-if="editedByLabel" :label="__('Updated by')">
      <span v-tooltip.supportive="editedByLabel" class="line-clamp-1">
        {{ editedByLabel }}
      </span>
    </CommonObjectAttribute>
  </CommonObjectAttributeContainer>

  <!-- Editors only, and read-only here: what an answer is going to become is editorial, and this is
       the reading view - the entry is removed, and a new one scheduled, from the edit tab. Gated on
       the answer's own policy rather than on the global permission, since granular permissions can
       leave the same user an editor of one subtree and a reader of the next. -->
  <KnowledgeBaseAnswerScheduledVisibility
    v-if="answer.policy.update"
    :answer="answer"
    class="p-3"
  />

  <KnowledgeBaseAnswerTags :answer="answer" class="p-3" />

  <KnowledgeBaseAnswerLinkedTickets :answer="answer" class="p-3" />
</template>
