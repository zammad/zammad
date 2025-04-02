<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import { useConfirmation } from '#shared/composables/useConfirmation.ts'
import { i18n } from '#shared/i18n.ts'

import CommonDialog from '#desktop/components/CommonDialog/CommonDialog.vue'

import type { ConfirmationVariantOptions } from './types.ts'

const { confirmationOptions } = useConfirmation()

interface Props {
  uniqueId: string
}

const props = defineProps<Props>()

const currentConfirmationOptions = computed(() => {
  return confirmationOptions.value?.get(props.uniqueId)
})

const handleConfirmation = (isCancel?: boolean) => {
  if (isCancel) {
    currentConfirmationOptions.value?.cancelCallback()
  } else if (isCancel === false) {
    currentConfirmationOptions.value?.confirmCallback()
  } else {
    currentConfirmationOptions.value?.closeCallback()
  }

  confirmationOptions.value.delete(props.uniqueId)
}

const confirmationVariant = computed<ConfirmationVariantOptions>(() => {
  switch (currentConfirmationOptions.value?.confirmationVariant) {
    case 'delete':
      return {
        headerTitle: __('Delete Object'),
        headerIcon: 'trash3',
        content: __('Are you sure you want to delete this object?'),
        footerActionOptions: {
          actionLabel:
            currentConfirmationOptions.value?.buttonLabel ||
            __('Delete Object'),
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
          actionLabel:
            currentConfirmationOptions.value?.buttonLabel || __('Yes'),
          actionButton: {
            variant:
              currentConfirmationOptions.value?.buttonVariant || 'primary',
          },
          cancelLabel: currentConfirmationOptions.value?.cancelLabel,
          hideCancelButton: currentConfirmationOptions.value?.hideCancelButton,
        },
      }
  }
})

const headerTitle = computed(() => {
  if (currentConfirmationOptions.value?.headerTitle) {
    return i18n.t(
      currentConfirmationOptions.value?.headerTitle,
      ...(currentConfirmationOptions.value?.headerTitlePlaceholder || []),
    )
  }

  return confirmationVariant.value.headerTitle
})
</script>

<template>
  <CommonDialog
    :name="`confirmation:${props.uniqueId}`"
    :header-title="headerTitle"
    :header-icon="
      currentConfirmationOptions?.headerIcon || confirmationVariant.headerIcon
    "
    :content="currentConfirmationOptions?.text || confirmationVariant.content"
    :content-placeholder="currentConfirmationOptions?.textPlaceholder"
    :footer-action-options="confirmationVariant.footerActionOptions"
    :fullscreen="currentConfirmationOptions?.fullscreen ?? false"
    global
    @close="handleConfirmation"
  />
</template>
