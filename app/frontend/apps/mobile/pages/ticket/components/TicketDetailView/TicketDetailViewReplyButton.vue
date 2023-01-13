<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useTicketInformation } from '../../composable/useTicketInformation'

const { newTicketArticlePresent, showArticleReplyDialog } =
  useTicketInformation()
</script>

<template>
  <button
    class="fixed bottom-0 flex h-12 w-screen items-center justify-center rounded-t-lg bg-gray-600 pb-1"
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
