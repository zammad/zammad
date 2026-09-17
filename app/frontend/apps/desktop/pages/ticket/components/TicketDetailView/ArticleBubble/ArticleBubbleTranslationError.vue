<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import type { TicketArticle } from '#shared/entities/ticket/types.ts'

import { useTicketInformation } from '#desktop/pages/ticket/composables/useTicketInformation.ts'

interface Props {
  article: TicketArticle
}

const props = defineProps<Props>()

const { articleTranslation } = useTicketInformation()

const error = computed(() => {
  const translation = articleTranslation.translationFor(props.article.id)

  return translation?.status === 'error' ? translation.error : undefined
})
</script>

<template>
  <!-- No retry on purpose: a failure of the translation service is rarely fixed by asking again;
    the original stays on screen and the administrator is the one to turn to. -->
  <CommonAlert v-if="error !== undefined" class="rounded-none" variant="warning">
    <p>
      {{ $t('Failed to translate article content.') }}
      {{ $t('Please contact your administrator.') }}
    </p>
    <p v-if="error">{{ $t(error) }}</p>
  </CommonAlert>
</template>
