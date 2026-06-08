<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'

interface Props {
  submitLabel?: string
  submitDisabled?: boolean
  cancelLabel?: string
  cancelDisabled?: boolean
}

defineProps<Props>()

defineEmits<{
  submit: [MouseEvent | KeyboardEvent]
  cancel: [MouseEvent | KeyboardEvent]
}>()
</script>

<template>
  <div class="flex gap-1">
    <CommonButton
      v-tooltip="cancelLabel || $t('Cancel')"
      icon="x-lg"
      variant="danger"
      :disabled="cancelDisabled"
      @click="$emit('cancel', $event)"
      @keydown.enter.stop="$emit('cancel', $event)"
    />
    <CommonButton
      v-tooltip="submitLabel || $t('Save changes')"
      class="rtl:-order-1"
      icon="check2"
      variant="submit"
      :disabled="submitDisabled"
      @click="$emit('submit', $event)"
      @keydown.enter.stop="$emit('submit', $event)"
    />
  </div>
</template>
