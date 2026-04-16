<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { onKeyDown } from '@vueuse/core'
import { toRef } from 'vue'

import CommonLabel from '#shared/components/CommonLabel/CommonLabel.vue'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import { useTicketBulkUpdateStore } from '#desktop/entities/user/current/stores/ticketBulkUpdate.ts'

import { useTicketBulkEdit } from '../TicketBulkEditFlyout/useTicketBulkEdit.ts'

import { DragAndDropBulkEntityType } from './types.ts'

const bulkUpdateStore = useTicketBulkUpdateStore()
const currentActiveEntityType = toRef(bulkUpdateStore, 'currentActiveEntityType')
const { confirmBulkAction, cancelBulkAction } = bulkUpdateStore

const { currentSelectedTicketCount } = useTicketBulkEdit()

onKeyDown('Escape', cancelBulkAction)
</script>

<template>
  <dialog
    open
    class="flex min-w-lg flex-col gap-3 rounded-xl border border-neutral-100 bg-neutral-50 p-3 focus:outline-none dark:border-gray-900 dark:bg-gray-500"
  >
    <div class="flex items-center justify-between bg-neutral-50 dark:bg-gray-500">
      <div class="flex items-center gap-2 text-xl leading-snug text-gray-100 dark:text-neutral-400">
        <CommonLabel size="xl" tag="h3">{{ $t('Confirm bulk action') }}</CommonLabel>
      </div>
      <CommonButton
        class="ms-auto"
        variant="neutral"
        size="medium"
        icon="x-lg"
        :aria-label="$t('Close dialog')"
        @click="cancelBulkAction"
      />
    </div>

    <div class="py-6 text-center">
      <CommonLabel class="max-w-xs" size="large">
        {{
          currentActiveEntityType === DragAndDropBulkEntityType.Macro
            ? $t(
                'You’re about to apply a macro to %s tickets. Do you want to continue?',
                currentSelectedTicketCount,
              )
            : $t(
                'You’re about to assign %s tickets. Do you want to continue?',
                currentSelectedTicketCount,
              )
        }}
      </CommonLabel>
    </div>

    <div class="flex items-center gap-2 ltr:justify-end rtl:flex-row-reverse rtl:justify-start">
      <CommonButton size="large" variant="secondary" @click="cancelBulkAction">
        {{ $t('Cancel & go back') }}
      </CommonButton>
      <CommonButton size="large" variant="primary" @click="confirmBulkAction">
        {{
          currentActiveEntityType === DragAndDropBulkEntityType.Macro
            ? $t('Run macro')
            : $t('Assign tickets')
        }}
      </CommonButton>
    </div>
  </dialog>
</template>
