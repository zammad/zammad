<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useTicketInformation } from '../../composable/useTicketInformation.ts'

const { newTicketArticlePresent, showArticleReplyDialog } =
  useTicketInformation()
</script>

<template>
  <button
    type="button"
    class="fixed bottom-0 flex w-screen items-center justify-center bg-gray-600 pt-3 pb-safe-4"
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
