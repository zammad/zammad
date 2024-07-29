<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { toRef } from 'vue'

import { useWhatsapp } from '#shared/entities/ticket/channel/composables/useWhatsapp.ts'
import type { TicketArticle } from '#shared/entities/ticket/types.ts'

interface Props {
  context: {
    article: TicketArticle
  }
}

const props = defineProps<Props>()

const { articleDeliveryStatus } = useWhatsapp(toRef(props.context, 'article'))
</script>

<template>
  <div class="flex items-center gap-1.5">
    <CommonIcon
      text-neutral-950
      class="text-black dark:text-white"
      width="16"
      height="16"
      name="whatsapp"
    />

    <CommonLabel class="text-neutral-950 dark:text-white">
      {{ $t('whatsapp message') }}
    </CommonLabel>

    <CommonIcon
      v-if="articleDeliveryStatus?.icon"
      width="16"
      height="16"
      :name="articleDeliveryStatus?.icon"
    />
    <CommonLabel>{{ articleDeliveryStatus?.message }}</CommonLabel>
  </div>
</template>
