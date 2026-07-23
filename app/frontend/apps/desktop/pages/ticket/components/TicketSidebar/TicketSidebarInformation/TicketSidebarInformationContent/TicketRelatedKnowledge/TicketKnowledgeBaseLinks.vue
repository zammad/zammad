<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->
<script setup lang="ts">
import { toRef } from 'vue'

import type { KnowledgeBaseAnswerTranslationFragment } from '#shared/graphql/types.ts'
import { getIdFromGraphQLId } from '#shared/graphql/utils.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import { useKnowledgeBaseStore } from '#desktop/entities/knowledge-base/stores/knowledgeBase.ts'
import { useTicketInformation } from '#desktop/pages/ticket/composables/useTicketInformation.ts'

import { useKnowledgeBaseAnswerLinks } from './composables/useKnowledgeBaseAnswerLinks.ts'
import TicketKnowledgeBaseAnswer from './TicketKnowledgeBaseAnswer.vue'

interface Props {
  linkedAnswers: KnowledgeBaseAnswerTranslationFragment[]
  targetType: string
  isTicketEditable: boolean
}

const props = defineProps<Props>()

const { ticketId } = useTicketInformation()

const { unlinkAnswer } = useKnowledgeBaseAnswerLinks(ticketId.value, props.targetType)

const store = useKnowledgeBaseStore()
const knowledgeBase = toRef(store, 'knowledgeBase')

// :TODO link needs to be updated when the answer view is available.
const answerLink = (translation: KnowledgeBaseAnswerTranslationFragment) => {
  const kb = knowledgeBase.value
  if (!kb) return undefined

  const locale = kb.currentLocale?.systemLocale.locale
  return `/#knowledge_base/${getIdFromGraphQLId(kb.id)}/locale/${locale}/answer/${getIdFromGraphQLId(translation.id)}`
}
</script>
<template>
  <CommonLabel tag="h3" size="small" class="text-stone-200! dark:text-neutral-500!">
    {{ $t('Linked') }}
  </CommonLabel>

  <ul v-if="knowledgeBase">
    <TicketKnowledgeBaseAnswer
      v-for="translation in linkedAnswers"
      :key="translation.id"
      :translation="translation"
      :link="answerLink(translation)"
    >
      <template v-if="isTicketEditable" #action="{ hasOpenedViaLongPress }">
        <CommonButton
          v-tooltip="$t('Unlink knowledge base answer')"
          class="opacity-0 group-hover:opacity-100 focus-visible:opacity-100"
          :class="{ 'opacity-100': hasOpenedViaLongPress }"
          size="small"
          variant="remove"
          icon="x-lg"
          @click="unlinkAnswer(translation.id)"
        /> </template
    ></TicketKnowledgeBaseAnswer>
  </ul>
</template>
