<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { toRef } from 'vue'

import { useForm } from '#shared/components/Form/useForm.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'

import type { ActionFooterOptions as Props } from './types.ts'

const props = withDefaults(defineProps<Props>(), {
  actionLabel: __('Update'),
  cancelLabel: __('Cancel & Go Back'),
})

const emit = defineEmits<{
  cancel: []
  action: []
}>()

const { isDisabled, formNodeId } = useForm(toRef(props, 'form'))

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
      size="large"
      :disabled="isDisabled || cancelButton?.disabled"
      :prefix-icon="cancelButton?.prefixIcon"
      :variant="cancelButton?.variant || 'secondary'"
      @click="cancel()"
    >
      {{ $t(cancelLabel) }}
    </CommonButton>
    <CommonButton
      v-if="!hideActionButton"
      size="large"
      :disabled="isDisabled || actionButton?.disabled"
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
