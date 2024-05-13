<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonButton, {
  type Props as ButtonProps,
} from '#desktop/components/CommonButton/CommonButton.vue'

export interface Props {
  hideActionButton?: boolean
  actionLabel?: string
  actionButton?: Pick<ButtonProps, 'prefixIcon' | 'variant'>
  hideCancelButton?: boolean
  cancelLabel?: string
  cancelButton?: Pick<ButtonProps, 'prefixIcon' | 'variant'>
}

withDefaults(defineProps<Props>(), {
  actionLabel: __('OK'),
  cancelLabel: __('Cancel & Go Back'),
})

const emit = defineEmits<{
  cancel: []
  action: []
}>()

const cancel = () => {
  emit('cancel')
}

const action = () => {
  emit('action')
}
</script>

<template>
  <!-- TODO: rtl button order? -->
  <div
    class="flex items-center gap-2 ltr:justify-end rtl:flex-row-reverse rtl:justify-start"
  >
    <CommonButton
      v-if="!hideCancelButton"
      size="large"
      :prefix-icon="cancelButton?.prefixIcon"
      :variant="cancelButton?.variant || 'secondary'"
      @click="cancel()"
    >
      {{ $t(cancelLabel) }}
    </CommonButton>
    <CommonButton
      v-if="!hideActionButton"
      size="large"
      :prefix-icon="actionButton?.prefixIcon"
      :variant="actionButton?.variant || 'primary'"
      @click="action()"
    >
      {{ $t(actionLabel) }}
    </CommonButton>
  </div>
</template>
