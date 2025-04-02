<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { toRef } from 'vue'

import { useArticleSecurity } from '#shared/composables/useArticleSecurity.ts'
import type { TicketArticle } from '#shared/entities/ticket/types.ts'

interface Props {
  context: {
    article: TicketArticle
  }
}

const props = defineProps<Props>()

const {
  typeLabel,
  signingIcon,
  encryptionIcon,
  encryptionMessage,
  signedStatusMessage,
  encryptedStatusMessage,
  signingMessage,
  isEncrypted,
  isSigned,
} = useArticleSecurity(toRef(props.context.article))
</script>

<template>
  <div class="flex items-center gap-1.5">
    <CommonLabel v-if="typeLabel">{{ typeLabel }}</CommonLabel>

    <CommonLabel
      v-if="isEncrypted"
      v-tooltip="encryptionMessage"
      :prefix-icon="encryptionIcon"
      class="text-black! dark:text-white!"
    >
      {{ $t(encryptedStatusMessage) }}
    </CommonLabel>

    <CommonLabel
      v-if="isSigned"
      v-tooltip="signingMessage"
      :prefix-icon="signingIcon"
      class="text-black! dark:text-white!"
    >
      {{ $t(signedStatusMessage) }}
    </CommonLabel>
  </div>
</template>
