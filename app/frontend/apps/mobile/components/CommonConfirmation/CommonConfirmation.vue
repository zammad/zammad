<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'
import CommonSectionPopup from '#mobile/components/CommonSectionPopup/CommonSectionPopup.vue'
import { useConfirmationDialog } from './useConfirmationDialog.ts'

// TODO: Add a story for this component.

const { confirmationDialog } = useConfirmationDialog()

const localState = computed({
  get: () => !!confirmationDialog.value,
  set: (value) => {
    if (!value) confirmationDialog.value = undefined
  },
})

const item = computed(() => {
  return {
    type: 'button' as const,
    label: confirmationDialog.value?.buttonTitle || __('OK'),
    buttonVariant: confirmationDialog.value?.buttonVariant,
    onAction: confirmationDialog.value?.confirmCallback,
  }
})

const callCancelCallback = (isCancel: boolean) => {
  if (!isCancel) return

  if (confirmationDialog.value?.cancelCallback) {
    confirmationDialog.value.cancelCallback()
  }
}
</script>

<template>
  <CommonSectionPopup
    v-model:state="localState"
    :messages="[item]"
    :heading="__('Confirm dialog')"
    @close="callCancelCallback"
  >
    <template #header>
      <div
        class="flex min-h-[3.5rem] items-center justify-center border-b border-gray-300 p-3 text-center text-white"
      >
        {{
          $t(
            confirmationDialog?.heading,
            ...(confirmationDialog?.headingPlaceholder || []),
          )
        }}
      </div>
    </template>
  </CommonSectionPopup>
</template>
