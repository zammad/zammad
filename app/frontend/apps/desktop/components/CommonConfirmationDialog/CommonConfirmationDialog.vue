<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import { useConfirmation } from '#shared/composables/useConfirmation.ts'
import { i18n } from '#shared/i18n.ts'

import CommonDialog from '#desktop/components/CommonDialog/CommonDialog.vue'

import type { ConfirmationVariantOptions } from './types.ts'

const { confirmationOptions } = useConfirmation()

const handleConfirmation = (isCancel?: boolean) => {
  if (isCancel) {
    confirmationOptions.value?.cancelCallback()
  } else if (isCancel === false) {
    confirmationOptions.value?.confirmCallback()
  } else {
    confirmationOptions.value?.closeCallback()
  }

  confirmationOptions.value = undefined
}

const confirmationVariant = computed<ConfirmationVariantOptions>(() => {
  switch (confirmationOptions.value?.confirmationVariant) {
    case 'delete':
      return {
        headerTitle: __('Delete Object'),
        headerIcon: 'trash3',
        content: __('Are you sure you want to delete this object?'),
        footerActionOptions: {
          actionLabel:
            confirmationOptions.value?.buttonLabel || __('Delete Object'),
          actionButton: {
            variant: 'danger',
          },
        },
      }
    case 'unsaved':
      return {
        headerTitle: __('Unsaved Changes'),
        content: __(
          'Are you sure? You have unsaved changes that will get lost.',
        ),
        footerActionOptions: {
          actionLabel: __('Discard Changes'),
          actionButton: {
            variant: 'danger',
          },
        },
      }
    default:
      return {
        headerTitle: __('Confirmation'),
        content: __('Do you want to continue?'),
        footerActionOptions: {
          actionLabel: confirmationOptions.value?.buttonLabel || __('Yes'),
          actionButton: {
            variant: confirmationOptions.value?.buttonVariant || 'primary',
          },
          cancelLabel: confirmationOptions.value?.cancelLabel,
        },
      }
  }
})

const headerTitle = computed(() => {
  if (confirmationOptions.value?.headerTitle) {
    return i18n.t(
      confirmationOptions.value?.headerTitle,
      ...(confirmationOptions.value?.headerTitlePlaceholder || []),
    )
  }

  return confirmationVariant.value.headerTitle
})
</script>

<template>
  <CommonDialog
    name="confirmation"
    :header-title="headerTitle"
    :header-icon="
      confirmationOptions?.headerIcon || confirmationVariant.headerIcon
    "
    :content="confirmationOptions?.text || confirmationVariant.content"
    :content-placeholder="confirmationOptions?.textPlaceholder"
    :footer-action-options="confirmationVariant.footerActionOptions"
    @close="handleConfirmation"
  ></CommonDialog>
</template>
