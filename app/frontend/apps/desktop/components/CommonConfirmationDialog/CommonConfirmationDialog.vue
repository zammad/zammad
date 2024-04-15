<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import CommonDialog from '#desktop/components/CommonDialog/CommonDialog.vue'

import { i18n } from '#shared/i18n.ts'
import { useConfirmation } from '#shared/composables/useConfirmation.ts'
import type { Props as CommonDialogActionFooterProps } from '../CommonDialog/CommonDialogActionFooter.vue'

const { confirmationOptions } = useConfirmation()

const headerTitle = computed(() => {
  return i18n.t(
    confirmationOptions.value?.headerTitle || __('Confirmation'),
    ...(confirmationOptions.value?.headerTitlePlaceholder || []),
  )
})

const footerActionOptions = computed<Partial<CommonDialogActionFooterProps>>(
  () => {
    return {
      actionLabel: confirmationOptions.value?.buttonLabel || __('OK'),
      actionButton: {
        variant: confirmationOptions.value?.buttonVariant || 'primary',
      },
    }
  },
)

const handleConfirmation = (isCancel: boolean) => {
  if (isCancel) {
    confirmationOptions.value?.cancelCallback()
  } else {
    confirmationOptions.value?.confirmCallback()
  }

  confirmationOptions.value = undefined
}

// TODO: add maybe different variants which can be used by default
</script>

<template>
  <CommonDialog
    name="confirmation"
    :header-title="headerTitle"
    :content="confirmationOptions?.text"
    :content-placeholder="confirmationOptions?.textPlaceholder"
    :footer-action-options="footerActionOptions"
    @close="handleConfirmation"
  ></CommonDialog>
</template>
