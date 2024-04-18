<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonButton, {
  type Props as ButtonProps,
} from '#desktop/components/CommonButton/CommonButton.vue'
import { useForm } from '#shared/components/Form/useForm.ts'
import { toRef } from 'vue'
import type { FormRef } from '#shared/components/Form/types.ts'

export interface Props {
  hideActionButton?: boolean
  actionLabel?: string
  actionButton?: Pick<
    ButtonProps,
    'prefixIcon' | 'variant' | 'type' | 'disabled'
  >
  cancelLabel?: string
  cancelButton?: Pick<ButtonProps, 'prefixIcon' | 'variant' | 'disabled'>
  form?: FormRef
}

const props = withDefaults(defineProps<Props>(), {
  actionLabel: __('Update'),
  cancelLabel: __('Cancel & Go Back'),
})

const emit = defineEmits<{
  cancel: []
  action: []
}>()

// ** Form // **
const { isDisabled, formNodeId } = useForm(toRef(props, 'form'))

const cancel = () => {
  emit('cancel')
}

const execute = () => {
  emit('action')
}
</script>

<template>
  <div class="flex items-center justify-end gap-2">
    <CommonButton
      size="medium"
      :disabled="isDisabled || cancelButton?.disabled"
      :prefix-icon="cancelButton?.prefixIcon"
      :variant="cancelButton?.variant || 'secondary'"
      @click="cancel()"
    >
      {{ $t(cancelLabel) }}
    </CommonButton>
    <CommonButton
      v-if="!hideActionButton"
      size="medium"
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
