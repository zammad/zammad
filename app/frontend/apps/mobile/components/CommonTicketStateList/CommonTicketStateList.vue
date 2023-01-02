<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { TicketState } from '@shared/entities/ticket/types'
import { replaceTags } from '@shared/utils/formatter'
import CommonSectionMenu from '../CommonSectionMenu/CommonSectionMenu.vue'
import CommonSectionMenuLink from '../CommonSectionMenu/CommonSectionMenuLink.vue'

interface Props {
  createLink?: string
  createLabel?: string
  counts: Record<TicketState.Closed | TicketState.Open, number>
  ticketsLinkQuery: string
}

const props = defineProps<Props>()

const getTicketsLink = (stateIds: number[]) => {
  const states = stateIds
    .map((stateId) => `state.state_type_id: ${stateId}`)
    .join(' OR ')
  return replaceTags(`/search/ticket?search=(${states}) AND #{query}`, {
    query: props.ticketsLinkQuery,
  })
}
</script>

<template>
  <CommonSectionMenu header-label="Tickets">
    <slot name="before-fields" />
    <CommonSectionMenuLink
      :icon="{
        name: 'mobile-check-circle-no',
        size: 'base',
        class: 'text-yellow',
        decorative: true,
      }"
      :information="counts[TicketState.Open]"
      :link="getTicketsLink([1, 2, 3, 4])"
    >
      {{ $t('open') }}
    </CommonSectionMenuLink>
    <CommonSectionMenuLink
      :icon="{
        name: 'mobile-check-circle-outline',
        size: 'base',
        class: 'text-green',
        decorative: true,
      }"
      :information="counts[TicketState.Closed]"
      :link="getTicketsLink([5])"
    >
      {{ $t('closed') }}
    </CommonSectionMenuLink>
    <CommonLink
      v-if="createLink && createLabel"
      class="flex min-h-[54px] items-center justify-center gap-2 text-blue"
      :link="createLink"
    >
      <CommonIcon name="mobile-add" size="tiny" decorative />
      {{ $t(createLabel) }}
    </CommonLink>
  </CommonSectionMenu>
</template>
