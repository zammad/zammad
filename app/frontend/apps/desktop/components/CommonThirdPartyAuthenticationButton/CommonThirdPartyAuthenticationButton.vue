<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { getCSRFToken } from '#shared/server/apollo/utils/csrfToken.ts'
import type { ButtonVariant } from '#shared/types/button.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import type { ButtonSize } from '#desktop/components/CommonButton/types.ts'

interface Props {
  buttonClass?: string
  buttonLabel?: string
  buttonIcon?: string
  buttonPrefixIcon?: string
  buttonVariant?: ButtonVariant
  buttonSize?: ButtonSize
  buttonBlock?: boolean
  url: string
  disabled?: boolean
}

withDefaults(defineProps<Props>(), {
  buttonVariant: 'secondary',
  buttonSize: 'small',
})

defineEmits<{
  'button-click': []
}>()

const csrfToken = getCSRFToken()
</script>

<template>
  <form role="form" method="post" :action="url">
    <input type="hidden" name="authenticity_token" :value="csrfToken" />
    <CommonButton
      v-tooltip="$t(buttonLabel)"
      type="submit"
      :class="buttonClass"
      :size="buttonSize"
      :variant="buttonVariant"
      :disabled="disabled"
      :block="buttonBlock"
      :prefix-icon="buttonPrefixIcon"
      :icon="buttonIcon"
      @click="$emit('button-click')"
    >
      <slot />
    </CommonButton>
  </form>
</template>
