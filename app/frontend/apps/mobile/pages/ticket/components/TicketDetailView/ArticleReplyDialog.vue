<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { ShallowRef } from 'vue'
import type { FormKitNode } from '@formkit/core'
import { cloneDeep, isEqual } from 'lodash-es'
import { computed, onMounted, onUnmounted } from 'vue'
import CommonDialog from '@mobile/components/CommonDialog/CommonDialog.vue'
import { closeDialog } from '@shared/composables/useDialog'
import type { TicketById } from '@shared/entities/ticket/types'
import type { FormRef } from '@shared/components/Form'
import { useConfirmationDialog } from '@mobile/components/CommonConfirmation'

interface Props {
  name: string
  ticket: TicketById
  articleFormGroupNode?: FormKitNode
  newTicketArticlePresent: boolean
  form: ShallowRef<FormRef | undefined>
}

const props = defineProps<Props>()

const emit = defineEmits<{
  (e: 'showArticleForm'): void
  (e: 'hideArticleForm'): void
  (e: 'discard'): void
  (e: 'done'): void
}>()

const label = computed(() =>
  props.newTicketArticlePresent ? __('Edit reply') : __('Add reply'),
)

const { waitForConfirmation } = useConfirmationDialog()

const articleFormGroupNodeContext = computed(
  () => props.articleFormGroupNode?.context,
)

const rememberArticleFormData = cloneDeep(
  articleFormGroupNodeContext.value?._value,
)

const dialogFormIsDirty = computed(() => {
  if (!props.newTicketArticlePresent)
    return !!articleFormGroupNodeContext.value?.state.dirty

  return !isEqual(
    rememberArticleFormData,
    articleFormGroupNodeContext.value?._value,
  )
})

const cancelDialog = async () => {
  if (dialogFormIsDirty.value) {
    const confirmed = await waitForConfirmation(
      __('Are you sure? You have changes that will get lost.'),
    )

    if (!confirmed) return
  }

  // Set article form data back to the remembered state.
  // For the first time we need to do nothing, because the article
  // group will be removed again from the form.
  if (props.newTicketArticlePresent) {
    props.articleFormGroupNode?.input(rememberArticleFormData)
  }

  closeDialog(props.name)
}

const discardDialog = async () => {
  const confirmed = await waitForConfirmation(
    __('Are you sure? The prepared article will be removed.'),
  )

  if (!confirmed) return

  // Reset only the article group.
  props.articleFormGroupNode?.reset()

  emit('discard')
  closeDialog(props.name)
}

onMounted(() => {
  emit('showArticleForm')
})

onUnmounted(() => {
  emit('hideArticleForm')
})

const close = () => {
  emit('done')
  closeDialog(props.name)
}
</script>

<template>
  <CommonDialog class="w-full" no-autofocus :name="name" :label="label">
    <template #before-label>
      <button class="text-white" @click="cancelDialog">
        {{ $t('Cancel') }}
      </button>
    </template>
    <template #after-label>
      <button
        class="grow text-blue disabled:opacity-50"
        tabindex="0"
        role="button"
        :disabled="!dialogFormIsDirty"
        @pointerdown.stop
        @click="close()"
        @keypress.space.prevent="close()"
      >
        {{ $t('Done') }}
      </button>
    </template>
    <div class="w-full p-4">
      <div data-ticket-article-reply-form />
      <FormKit
        v-if="newTicketArticlePresent"
        wrapper-class="mt-4 flex grow justify-center items-center"
        input-class="py-2 px-4 w-full h-14 text-base !text-red-bright formkit-variant-primary:bg-red-dark rounded-xl select-none"
        type="button"
        name="discardArticle"
        @click="discardDialog"
      >
        {{ $t('Discard your unsaved changes') }}
      </FormKit>
    </div>
  </CommonDialog>
</template>
