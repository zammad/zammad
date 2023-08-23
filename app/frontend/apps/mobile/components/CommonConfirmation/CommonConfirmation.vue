<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'
import CommonSectionPopup from '#mobile/components/CommonSectionPopup/CommonSectionPopup.vue'
import { confirmationOptions } from '#shared/utils/confirmation.ts'

const localState = computed({
  get: () => !!confirmationOptions.value,
  set: (value) => {
    if (!value) confirmationOptions.value = undefined
  },
})

const item = computed(() => {
  return {
    type: 'button' as const,
    label: confirmationOptions.value?.buttonTitle || __('OK'),
    buttonVariant: confirmationOptions.value?.buttonVariant,
    onAction: confirmationOptions.value?.confirmCallback,
  }
})

const callCancelCallback = (isCancel: boolean) => {
  if (!isCancel) return

  if (confirmationOptions.value?.cancelCallback) {
    confirmationOptions.value.cancelCallback()
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
            confirmationOptions?.heading,
            ...(confirmationOptions?.headingPlaceholder || []),
          )
        }}
      </div>
    </template>
  </CommonSectionPopup>
</template>
