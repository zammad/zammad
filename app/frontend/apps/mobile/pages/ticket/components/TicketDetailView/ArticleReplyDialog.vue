<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { cloneDeep, isEqual } from 'lodash-es'
import { computed, onMounted, onUnmounted, ref } from 'vue'

import type { FormRef } from '#shared/components/Form/types.ts'
import { useConfirmation } from '#shared/composables/useConfirmation.ts'
import type { TicketById } from '#shared/entities/ticket/types.ts'

import CommonButton from '#mobile/components/CommonButton/CommonButton.vue'
import CommonDialog from '#mobile/components/CommonDialog/CommonDialog.vue'
import { closeDialog } from '#mobile/composables/useDialog.ts'

import type { FormKitNode } from '@formkit/core'
import type { ShallowRef } from 'vue'

interface Props {
  name: string
  ticket: TicketById
  articleFormGroupNode?: FormKitNode
  newTicketArticlePresent: boolean
  needSpaceForSaveBanner: boolean
  form: ShallowRef<FormRef | undefined>
}

const props = defineProps<Props>()

const emit = defineEmits<{
  'show-article-form': []
  'hide-article-form': []
  discard: []
  done: []
}>()

const label = computed(() => (props.newTicketArticlePresent ? __('Edit reply') : __('Add reply')))
const firstChangeDetected = ref(false)

const articleFormGroupNodeContext = computed(() => props.articleFormGroupNode?.context)

const rememberArticleFormData = cloneDeep({
  ...articleFormGroupNodeContext.value?._value,
  __init: true,
})

const dialogFormIsDirty = computed(() => {
  if (!props.newTicketArticlePresent) return firstChangeDetected.value

  return !isEqual(rememberArticleFormData, articleFormGroupNodeContext.value?._value)
})

const { waitForConfirmation } = useConfirmation()

const cancelDialog = async () => {
  if (dialogFormIsDirty.value) {
    const confirmed = await waitForConfirmation(
      __('Are you sure? You have changes that will get lost.'),
      {
        buttonLabel: __('Discard changes'),
        buttonVariant: 'danger',
      },
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
    {
      buttonLabel: __('Discard article'),
      buttonVariant: 'danger',
    },
  )

  if (!confirmed) return

  // Reset only the article group.
  props.articleFormGroupNode?.reset()

  emit('discard')
  closeDialog(props.name)
}

onMounted(() => {
  emit('show-article-form')

  // We need a special handling for the initial reply dialog, because the article group is always dirty.
  // Because of that we waiting on the first article type value and then that this is settled to the form group.
  // After that we now that the next change inside the form values is a manual action and we can
  // set the first change detected flag.
  if (!props.newTicketArticlePresent && props.articleFormGroupNode) {
    const articleTypeNode = props.articleFormGroupNode.find('articleType', 'name')

    if (articleTypeNode) {
      const checkForGroupChangeInitialize = articleTypeNode.on('commit', async () => {
        props.articleFormGroupNode?.off(checkForGroupChangeInitialize)

        if (!props.articleFormGroupNode) return

        await props.articleFormGroupNode.settled

        const checkForFirstChange = props.articleFormGroupNode.on('commit', () => {
          firstChangeDetected.value = true
          props.articleFormGroupNode?.off(checkForFirstChange)
        })
      })
    }
  }
})

onUnmounted(() => {
  emit('hide-article-form')
})

const close = () => {
  emit('done')
  closeDialog(props.name)
}
</script>

<template>
  <CommonDialog class="w-full" :name="name" :label="label">
    <template #before-label>
      <CommonButton transparent-background @click="cancelDialog">
        {{ $t('Cancel') }}
      </CommonButton>
    </template>
    <template #after-label>
      <CommonButton
        variant="primary"
        :disabled="!dialogFormIsDirty"
        transparent-background
        @pointerdown.stop
        @click="close()"
        @keypress.space.prevent="close()"
      >
        {{ $t('Done') }}
      </CommonButton>
    </template>
    <div class="w-full p-4">
      <div data-ticket-article-reply-form />
      <FormKit
        v-if="newTicketArticlePresent"
        variant="danger"
        wrapper-class="mt-4 flex grow justify-center items-center"
        input-class="py-2 px-4 w-full h-14 rounded-xl select-none"
        name="discardArticle"
        type="button"
        @click="discardDialog"
      >
        {{ $t('Discard your unsaved changes') }}
      </FormKit>
      <div class="transition-all" :class="{ 'pb-16': needSpaceForSaveBanner }"></div>
    </div>
  </CommonDialog>
</template>
