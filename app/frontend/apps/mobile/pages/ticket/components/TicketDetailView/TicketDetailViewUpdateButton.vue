<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useTicketInformation } from '../../composable/useTicketInformation'

const { canUpdateTicket, canSubmitForm, isFormValid } = useTicketInformation()
</script>

<template>
  <button
    v-if="canUpdateTicket"
    class="relative z-10 h-10 w-10 rounded-full bg-yellow p-1 text-black disabled:bg-yellow-inactive"
    form="form-ticket-edit"
    :disabled="!canSubmitForm"
    :aria-label="$t('Save ticket')"
  >
    <div
      v-if="canSubmitForm && !isFormValid"
      role="status"
      :aria-label="$t('Validation failed')"
      class="absolute bottom-7 h-5 w-5 rounded-full bg-red text-center text-xs leading-5 text-black ltr:left-7 rtl:right-7"
    >
      <CommonIcon
        class="mx-auto h-5"
        name="mobile-close"
        size="tiny"
        decorative
      />
    </div>
    <CommonIcon name="mobile-arrow-up" decorative />
  </button>
</template>
