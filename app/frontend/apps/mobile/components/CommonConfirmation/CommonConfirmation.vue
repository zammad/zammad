<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import { useConfirmation } from '#shared/composables/useConfirmation.ts'
import { i18n } from '#shared/i18n.ts'

import CommonSectionPopup from '../CommonSectionPopup/CommonSectionPopup.vue'

import type { PopupItemDescriptor } from '../CommonSectionPopup/types.ts'

const { confirmationOptions } = useConfirmation()

const currentConfirmationOptions = computed(() => {
  return confirmationOptions.value?.get('confirmation')
})

const localState = computed({
  get: () => !!confirmationOptions.value.get('confirmation'),
  set: (value) => {
    if (!value) confirmationOptions.value.delete('confirmation')
  },
})

const item = computed(() => {
  return {
    type: 'button' as const,
    label: currentConfirmationOptions.value?.buttonLabel || __('OK'),
    buttonVariant: currentConfirmationOptions.value
      ?.buttonVariant as PopupItemDescriptor['buttonVariant'],
    onAction: currentConfirmationOptions.value?.confirmCallback,
  }
})

const callCancelCallback = (isCancel: boolean) => {
  if (!isCancel) return

  if (currentConfirmationOptions.value?.cancelCallback) {
    currentConfirmationOptions.value.cancelCallback()
  }
}

const heading = computed(() => {
  return i18n.t(
    currentConfirmationOptions.value?.headerTitle || __('Confirm dialog'),
    ...(currentConfirmationOptions.value?.headerTitlePlaceholder || []),
  )
})
</script>

<template>
  <CommonSectionPopup
    v-model:state="localState"
    :messages="[item]"
    :heading="heading"
    :cancel-label="currentConfirmationOptions?.cancelLabel"
    :fullscreen="currentConfirmationOptions?.fullscreen"
    @close="callCancelCallback"
  >
    <template #header>
      <div
        class="flex min-h-[3.5rem] items-center justify-center border-b border-gray-300 p-3 text-center text-white"
      >
        {{
          $t(
            currentConfirmationOptions?.text,
            ...(currentConfirmationOptions?.textPlaceholder || []),
          )
        }}
      </div>
    </template>
  </CommonSectionPopup>
</template>
