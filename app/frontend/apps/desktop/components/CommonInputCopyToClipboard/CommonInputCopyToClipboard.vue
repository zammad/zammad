<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useCopyToClipboard } from '#shared/composables/useCopyToClipboard.ts'

import CommonButton from '../CommonButton/CommonButton.vue'

interface Props {
  label: string
  labelPlaceholder?: string[]
  value: string
  copyButtonText?: string
  help?: string
}

withDefaults(defineProps<Props>(), {
  copyButtonText: __('Copy Text'),
})

const { copyToClipboard } = useCopyToClipboard()
</script>

<template>
  <FormKit
    type="text"
    :model-value="value"
    :label="label"
    :label-placeholder="labelPlaceholder"
    :help="help"
    readonly
  >
    <template #link="context">
      <div class="mb-0.5 ms-2 flex h-full items-center">
        <CommonButton
          prefix-icon="files"
          size="medium"
          :aria-describedby="context.id"
          @click="copyToClipboard(value)"
          >{{ $t(copyButtonText) }}</CommonButton
        >
      </div>
    </template>
  </FormKit>
</template>
