<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { TicketState } from '@shared/entities/ticket/types'
import CommonSectionMenu from '../CommonSectionMenu/CommonSectionMenu.vue'
import CommonSectionMenuLink from '../CommonSectionMenu/CommonSectionMenuLink.vue'

interface Props {
  createLink?: string
  createLabel?: string
  counts: Record<TicketState.Closed | TicketState.Open, number>
  ticketsLink(state: TicketState.Closed | TicketState.Open): string
}

defineProps<Props>()
</script>

<template>
  <CommonSectionMenu header-label="Tickets">
    <CommonSectionMenuLink
      :icon="{ name: 'state-open', size: 'base', class: 'text-yellow' }"
      :information="counts[TicketState.Open]"
      :link="ticketsLink(TicketState.Open)"
    >
      {{ $t('open') }}
    </CommonSectionMenuLink>
    <CommonSectionMenuLink
      :icon="{ name: 'state-closed', size: 'base', class: 'text-green' }"
      :information="counts[TicketState.Closed]"
      :link="ticketsLink(TicketState.Closed)"
    >
      {{ $t('closed') }}
    </CommonSectionMenuLink>
    <CommonLink
      v-if="createLink && createLabel"
      class="flex min-h-[54px] items-center justify-center gap-2 text-blue"
      :link="createLink"
    >
      <CommonIcon name="plus" size="tiny" />
      {{ $t(createLabel) }}
    </CommonLink>
  </CommonSectionMenu>
</template>
