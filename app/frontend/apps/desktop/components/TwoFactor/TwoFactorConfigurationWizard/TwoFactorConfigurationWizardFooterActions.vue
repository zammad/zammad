<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { toRef } from 'vue'

import { useForm } from '#shared/components/Form/useForm.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import type { ActionFooterOptions as Props } from '#desktop/components/CommonFlyout/types.ts'

const props = defineProps<Props>()

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
  <div class="flex flex-col gap-3">
    <CommonButton
      v-if="!hideActionButton"
      size="large"
      block
      :disabled="isDisabled || actionButton?.disabled"
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
      size="large"
      block
      :disabled="isDisabled || cancelButton?.disabled"
      :prefix-icon="cancelButton?.prefixIcon"
      :variant="cancelButton?.variant || 'secondary'"
      @click="cancel()"
    >
      {{ $t(cancelLabel) }}
    </CommonButton>
  </div>
</template>
