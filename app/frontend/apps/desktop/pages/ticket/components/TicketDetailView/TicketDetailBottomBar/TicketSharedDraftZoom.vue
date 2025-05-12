<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { FormRef } from '#shared/components/Form/types.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import { useTicketSharedDraft } from '#desktop/pages/ticket/composables/useTicketSharedDraft.ts'

const props = defineProps<{
  sharedDraftId?: string | null
  form?: FormRef
  setSkipNextStateUpdate: (skip: boolean) => void
}>()

const { openSharedDraftFlyout } = useTicketSharedDraft(
  props.setSkipNextStateUpdate,
)
</script>

<template>
  <div class="flex items-center gap-2.5">
    <CommonButton
      prefix-icon="template"
      size="large"
      variant="tertiary"
      @click="openSharedDraftFlyout('detail-view', sharedDraftId, form)"
      >{{ $t('Draft Available') }}</CommonButton
    >
  </div>
</template>
