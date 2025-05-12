<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import type { ActionFooterProps } from '#desktop/components/CommonFlyout/types.ts'

defineProps<ActionFooterProps>()

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
  <div class="flex flex-col gap-3">
    <CommonButton
      v-if="!hideActionButton"
      :key="formNodeId"
      size="large"
      block
      :disabled="isFormDisabled || actionButton?.disabled"
      :form="formNodeId"
      :type="actionButton?.type"
      :prefix-icon="actionButton?.prefixIcon"
      :variant="actionButton?.variant || 'submit'"
      @click="execute()"
    >
      {{ $t(actionLabel) || 'Submit' }}
    </CommonButton>
    <CommonButton
      v-if="!hideCancelButton"
      :key="formNodeId"
      size="large"
      block
      :disabled="isFormDisabled || cancelButton?.disabled"
      :prefix-icon="cancelButton?.prefixIcon"
      :variant="cancelButton?.variant || 'secondary'"
      @click="cancel()"
    >
      {{ $t(cancelLabel) }}
    </CommonButton>
  </div>
</template>
