<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useCopyToClipboard } from '#shared/composables/useCopyToClipboard.ts'

import CommonButton from '../CommonButton/CommonButton.vue'

interface Props {
  label: string
  labelPlaceholder?: string[]
  value: string
  copyButtonText?: string
  help?: string
  /**
   * Greys out the field and blocks copying, for while the value is known to be
   * outdated (e.g. a token being rotated).
   */
  disabled?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  copyButtonText: __('Copy text'),
})

const { copyToClipboard } = useCopyToClipboard()

// The button only signals its disabled state through `pointer-events-none`, so the
//   value is guarded here as well.
const copy = () => {
  if (props.disabled) return

  copyToClipboard(props.value)
}
</script>

<template>
  <FormKit
    type="text"
    :model-value="value"
    :label="label"
    :label-placeholder="labelPlaceholder"
    :help="help"
    :disabled="disabled"
    readonly
  >
    <template #link="context">
      <div class="ms-2 mb-0.5 flex h-full items-center">
        <CommonButton
          prefix-icon="files"
          size="medium"
          :disabled="disabled"
          :aria-describedby="context.id"
          @click="copy"
          >{{ $t(copyButtonText) }}</CommonButton
        >
      </div>
    </template>
  </FormKit>
</template>
