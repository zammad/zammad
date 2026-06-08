<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, nextTick, onMounted, shallowRef, useTemplateRef, unref } from 'vue'

import { useAiAnalyticsUsageMutation } from '#shared/graphql/mutations/aiAnalyticsUsage.api.ts'
import type { AiAnalyticsMetadata, AiAnalyticsUsageInput } from '#shared/graphql/types.ts'
import { MutationHandler } from '#shared/server/apollo/handler/index.ts'
import type { DeepPartial } from '#shared/types/utils.ts'

import type { UiState } from '#desktop/components/CommonAIFeedback/types.ts'
import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'

interface Props {
  analyticsMeta: DeepPartial<AiAnalyticsMetadata>
  label?: string
  noRegeneration?: boolean
}
const props = defineProps<Props>()

const emit = defineEmits<{ regenerate: []; rated: [] }>()

const uiState = shallowRef<UiState>('idle')

const comment = shallowRef('')
const commentFieldElement = useTemplateRef('comment-field')

const usageMutation = new MutationHandler(useAiAnalyticsUsageMutation())
const loading = usageMutation.loading()

const runId = computed(() => props.analyticsMeta?.run?.id)
const hasProvidedFeedback = computed(() => !!props.analyticsMeta?.usage?.userHasProvidedFeedback)

const submitUsage = async (input: AiAnalyticsUsageInput) => {
  if (!runId.value) return
  await usageMutation.send({ aiAnalyticsRunId: runId.value, input })
}

const submitPositiveFeedback = async () => {
  await submitUsage({ rating: true })
  uiState.value = 'success'
  emit('rated')
}

const submitNegativeFeedback = async () => {
  await submitUsage({ rating: false })
  uiState.value = 'comment'
  emit('rated')
  await nextTick()

  const commentContainer = unref(commentFieldElement)
  const textarea = commentContainer!.querySelector('textarea') as HTMLTextAreaElement

  textarea.scrollIntoView({ behavior: 'smooth', block: 'nearest' })
  textarea.focus()
}

const submitComment = async () => {
  await submitUsage({ comment: comment.value })
  uiState.value = 'success'
}

const cancelComment = () => {
  uiState.value = 'success'
}

const showActions = computed(() => uiState.value === 'idle' && !hasProvidedFeedback.value)
const showCommentField = computed(() => uiState.value === 'comment' && !hasProvidedFeedback.value)
const showSuccess = computed(() => uiState.value === 'success' || !hasProvidedFeedback.value)
const canRegenerate = computed(() => !props.noRegeneration && uiState.value !== 'comment')

onMounted(async () => {
  // Track usage once if not yet done.
  const usage = props.analyticsMeta?.usage
  if (!usage && runId.value) await submitUsage({ rating: null })
})
</script>

<template>
  <div>
    <CommonLabel v-if="label && !hasProvidedFeedback" class="col-span-2 mb-4" tag="h3">
      {{ label }}
    </CommonLabel>

    <div class="flex min-h-7 items-center gap-1">
      <template v-if="showActions">
        <CommonButton
          v-tooltip="$t('Positive feedback')"
          variant="neutral"
          icon="hand-thumbs-up"
          :disabled="loading"
          @click="submitPositiveFeedback"
        />
        <CommonButton
          v-tooltip="$t('Negative feedback')"
          variant="neutral"
          icon="hand-thumbs-down"
          :disabled="loading"
          @click="submitNegativeFeedback"
        />
      </template>

      <div v-else-if="showCommentField" ref="comment-field" class="w-full space-y-2">
        <FormKit
          id="feedback-comment"
          v-model="comment"
          :placeholder="$t('Thanks for the feedback. Please explain what went wrong?')"
          type="textarea"
        />
        <div class="flex justify-center gap-1">
          <CommonButton variant="secondary" @click="cancelComment">{{
            $t('No comment')
          }}</CommonButton>
          <CommonButton variant="tertiary" @click="submitComment">{{
            $t('Submit comment')
          }}</CommonButton>
        </div>
      </div>

      <div v-else class="flex-1">
        <CommonLabel v-if="showSuccess" size="small">
          {{ $t('Thank you for your feedback.') }}
        </CommonLabel>
      </div>

      <CommonButton
        v-if="canRegenerate"
        v-tooltip="$t('Regenerate')"
        class="relative ai-stripe before:absolute before:-bottom-0 before:left-1/2 before:h-[1px] before:w-[.7em] before:-translate-x-1/2 hover:animate-ai-stripe focus-visible:animate-ai-stripe ltr:ml-auto rtl:mr-auto"
        variant="tertiary"
        size="medium"
        icon="arrow-repeat"
        @click="$emit('regenerate')"
      />
    </div>
  </div>
</template>
