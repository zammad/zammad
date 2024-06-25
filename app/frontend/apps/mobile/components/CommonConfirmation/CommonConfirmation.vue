<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import { useConfirmation } from '#shared/composables/useConfirmation.ts'
import { i18n } from '#shared/i18n.ts'

import CommonSectionPopup from '../CommonSectionPopup/CommonSectionPopup.vue'

import type { PopupItemDescriptor } from '../CommonSectionPopup/types.ts'

const { confirmationOptions, showConfirmation } = useConfirmation()

const localState = computed({
  get: () => showConfirmation.value,
  set: (value) => {
    if (!value) confirmationOptions.value = undefined
  },
})

const item = computed(() => {
  return {
    type: 'button' as const,
    label: confirmationOptions.value?.buttonLabel || __('OK'),
    buttonVariant: confirmationOptions.value
      ?.buttonVariant as PopupItemDescriptor['buttonVariant'],
    onAction: confirmationOptions.value?.confirmCallback,
  }
})

const callCancelCallback = (isCancel: boolean) => {
  if (!isCancel) return

  if (confirmationOptions.value?.cancelCallback) {
    confirmationOptions.value.cancelCallback()
  }
}

const heading = computed(() => {
  return i18n.t(
    confirmationOptions.value?.headerTitle || __('Confirm dialog'),
    ...(confirmationOptions.value?.headerTitlePlaceholder || []),
  )
})
</script>

<template>
  <CommonSectionPopup
    v-model:state="localState"
    :messages="[item]"
    :heading="heading"
    :cancel-label="confirmationOptions?.cancelLabel"
    @close="callCancelCallback"
  >
    <template #header>
      <div
        class="flex min-h-[3.5rem] items-center justify-center border-b border-gray-300 p-3 text-center text-white"
      >
        {{
          $t(
            confirmationOptions?.text,
            ...(confirmationOptions?.textPlaceholder || []),
          )
        }}
      </div>
    </template>
  </CommonSectionPopup>
</template>
