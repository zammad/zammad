<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'

import type { ActionFooterProps } from './types.ts'

withDefaults(defineProps<ActionFooterProps>(), {
  actionLabel: __('Update'),
  cancelLabel: __('Cancel & Go Back'),
})

const emit = defineEmits<{
  cancel: []
  action: []
}>()

const cancel = () => {
  emit('cancel')
}

const execute = () => {
  emit('action')
}
</script>

<template>
  <div class="flex items-center justify-end gap-4">
    <CommonButton
      v-if="!hideCancelButton"
      :key="formNodeId"
      size="large"
      :disabled="isFormDisabled || cancelButton?.disabled"
      :prefix-icon="cancelButton?.prefixIcon"
      :variant="cancelButton?.variant || 'secondary'"
      @click="cancel()"
    >
      {{ $t(cancelLabel) }}
    </CommonButton>
    <CommonButton
      v-if="!hideActionButton"
      :key="formNodeId"
      size="large"
      :disabled="isFormDisabled || actionButton?.disabled"
      :form="formNodeId"
      :type="actionButton?.type"
      :prefix-icon="actionButton?.prefixIcon"
      :variant="actionButton?.variant || 'submit'"
      @click="execute()"
    >
      {{ $t(actionLabel) }}
    </CommonButton>
  </div>
</template>
