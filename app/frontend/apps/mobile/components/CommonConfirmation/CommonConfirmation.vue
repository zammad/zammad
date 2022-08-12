<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'
import CommonSectionPopup from '@mobile/components/CommonSectionPopup/CommonSectionPopup.vue'
import useConfirmation from './composable'

// TODO: Add a story for this component.

const { confirmationDialog } = useConfirmation()

const localState = computed({
  get: () => !!confirmationDialog.value,
  set: (value) => {
    if (!value) confirmationDialog.value = undefined
  },
})

const item = computed(() => {
  return {
    label: confirmationDialog.value?.buttonTitle || __('OK'),
    class: confirmationDialog.value?.buttonTextColorClass || 'text-white',
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
    :items="[item]"
    @close="callCancelCallback"
  >
    <template #header>
      <div
        class="flex h-14 items-center justify-center border-b border-gray-300 text-white"
      >
        {{ $t(confirmationDialog?.heading) }}
      </div>
    </template>
  </CommonSectionPopup>
</template>
