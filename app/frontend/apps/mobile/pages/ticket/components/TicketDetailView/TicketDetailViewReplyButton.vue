<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useTicketInformation } from '../../composable/useTicketInformation'

const { newTicketArticlePresent, showArticleReplyDialog } =
  useTicketInformation()
</script>

<template>
  <button
    type="button"
    class="Reply fixed bottom-0 flex w-screen items-center justify-center bg-gray-600 pt-3"
    @click="showArticleReplyDialog"
  >
    <template v-if="newTicketArticlePresent">
      {{ $t('Edit reply') }}
    </template>
    <template v-else>
      {{ $t('Add reply') }}
    </template>
  </button>
</template>

<style land="scss" scoped>
.Reply {
  padding-bottom: calc(var(--safe-bottom, 0) + theme('height.4'));
}
</style>
