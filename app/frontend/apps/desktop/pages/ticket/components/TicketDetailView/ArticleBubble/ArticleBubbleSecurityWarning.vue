<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { toRef } from 'vue'

import { useArticleSecurity } from '#shared/composables/useArticleSecurity.ts'
import type { TicketArticle } from '#shared/entities/ticket/types.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'

interface Props {
  article: TicketArticle
}

const props = defineProps<Props>()

const { hasError, signingMessage, encryptionMessage, retrySecurityProcess } =
  useArticleSecurity(toRef(props.article))
</script>

<template>
  <CommonAlert v-if="hasError" class="-:rounded-none" variant="warning">
    <div>
      <h2>{{ $t('Security Error') }}</h2>
      <p v-if="signingMessage">{{ $t('Sign:') }} {{ signingMessage }}</p>
      <p v-if="encryptionMessage">
        {{ $t('Encryption:') }} {{ encryptionMessage }}
      </p>
      <p v-if="!signingMessage && !encryptionMessage" class="block">
        {{ $t('No security information available.') }}
      </p>
      <CommonButton
        class="!p-0 !text-current underline hover:outline-transparent dark:hover:outline-transparent"
        size="medium"
        transparent-background
        @click="retrySecurityProcess"
        >{{ $t('Retry Security Process') }}</CommonButton
      >
    </div>
  </CommonAlert>
</template>
