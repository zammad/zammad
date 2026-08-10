<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useTouchDevice } from '#shared/composables/useTouchDevice.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import { useTicketInformation } from '#desktop/pages/ticket/composables/useTicketInformation.ts'

import { useKnowledgeBaseAnswerLinks } from './composables/useKnowledgeBaseAnswerLinks.ts'
import TicketKnowledgeBaseAnswer from './TicketKnowledgeBaseAnswer.vue'
import TicketKnowledgeBaseAnswerSkeleton from './TicketKnowledgeBaseAnswerSkeleton.vue'
import { getKnowledgeBaseAnswerLink } from './utils/knowledgeBaseAnswerLink.ts'

import type { RelatedAnswer } from './types.ts'

export interface Props {
  targetType: string
  answers: RelatedAnswer[]
  loading: boolean
  pending: boolean
  hasError: boolean
  errorDetail: string | null
  isTicketEditable: boolean
  showRelevanceScore: boolean
}

const props = defineProps<Props>()

defineEmits<{
  retry: []
}>()

const { ticketId } = useTicketInformation()

const { linkAnswer } = useKnowledgeBaseAnswerLinks(ticketId.value, props.targetType)

const { isTouchDevice } = useTouchDevice()
</script>

<template>
  <CommonLabel tag="h3" size="small" class="text-stone-200! dark:text-neutral-500!">
    {{ $t('Suggested by AI') }}
  </CommonLabel>
  <div v-if="hasError" class="flex flex-col items-end gap-3">
    <CommonAlert class="self-stretch" variant="danger">
      <div class="flex flex-col gap-1.5">
        <CommonLabel class="text-red-500 dark:text-red-500">
          {{
            $t(
              'The suggestions could not be generated. Please try again later or contact your administrator.',
            )
          }}
        </CommonLabel>
        <CommonLabel v-if="errorDetail" class="wrap-anywhere text-red-500 dark:text-red-500">
          {{ $t('API server error: %s', $t(errorDetail)) }}
        </CommonLabel>
      </div>
    </CommonAlert>
    <CommonButton variant="tertiary" @click="$emit('retry')">{{ $t('Retry') }}</CommonButton>
  </div>

  <CommonLoader v-else :loading="loading || pending">
    <ul v-if="answers.length">
      <TicketKnowledgeBaseAnswer
        v-for="answer in answers"
        :key="answer.translation.id"
        :translation="answer.translation"
        :link="getKnowledgeBaseAnswerLink(answer.translation)"
      >
        <template v-if="showRelevanceScore" #link-trailing>
          <CommonLabel
            v-tooltip.supportive="$t('Relevance score')"
            size="small"
            class="text-stone-200! dark:text-neutral-500!"
          >
            {{ `${answer.score}%` }}
          </CommonLabel>
        </template>
        <template v-if="isTicketEditable" #action="{ hasOpenedViaLongPress }">
          <CommonButton
            v-tooltip="$t('Link knowledge base answer')"
            :class="{
              'opacity-100': hasOpenedViaLongPress,
              'opacity-0 group-hover:opacity-100 focus-visible:opacity-100': !isTouchDevice,
            }"
            class="text-blue-800!"
            size="small"
            variant="none"
            icon="plus-square-fill"
            @click="linkAnswer(answer.translation.id)"
          />
        </template>
      </TicketKnowledgeBaseAnswer>
    </ul>

    <!-- Not "no answers found": the best matches may all be linked already, and those are listed
    above rather than suggested again. -->
    <CommonLabel v-else size="small" class="text-stone-200! dark:text-neutral-500!">
      {{ $t('No suggestions.') }}
    </CommonLabel>

    <template #skeleton>
      <ul>
        <TicketKnowledgeBaseAnswerSkeleton :label="__('Searching for related answers…')" />
      </ul>
    </template>
  </CommonLoader>
</template>
