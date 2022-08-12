<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'
import CommonInputSearch from '@shared/components/CommonInputSearch/CommonInputSearch.vue'
import { useSessionStore } from '@shared/stores/session'
import type { MenuItem } from '@mobile/components/CommonSectionMenu'
import CommonSectionMenu from '@mobile/components/CommonSectionMenu/CommonSectionMenu.vue'
import { useTicketsOverviews } from '@mobile/entities/ticket/stores/ticketOverviews'

const IS_DEV = import.meta.env.DEV

const session = useSessionStore()

const menu: MenuItem[] = [
  {
    type: 'link',
    link: '/tickets/view',
    label: __('Ticket Overviews'),
    icon: { name: 'stack', size: 'base' },
    iconBg: 'bg-pink',
    permission: ['ticket.agent', 'ticket.customer'],
  },
  // Cannot inline import.meta here, Vite fails
  ...(IS_DEV
    ? [
        {
          type: 'link' as const,
          link: '/playground',
          label: 'Playground',
          icon: { name: 'cog', size: 'small' as const },
          iconBg: 'bg-orange',
        },
      ]
    : []),
]

const overviews = useTicketsOverviews()

const ticketOverview = computed<MenuItem[]>(() => {
  if (overviews.loading) return []

  return overviews.includedOverviews.map((overview) => {
    return {
      type: 'link',
      link: `/tickets/view/${overview.link}`,
      label: overview.name,
      information: overview.ticketCount,
    }
  })
})
</script>

<template>
  <div class="p-4">
    <div class="my-6 flex justify-end ltr:mr-4 rtl:ml-4">
      <CommonLink link="/#ticket/create">
        <CommonIcon name="plus" size="small" />
      </CommonLink>
    </div>
    <div
      class="mb-5 flex w-full items-center justify-center text-4xl font-bold"
    >
      {{ $t('Home') }}
    </div>
    <CommonLink link="/search">
      <CommonInputSearch wrapper-class="mb-4" no-border />
    </CommonLink>
    <CommonSectionMenu :items="menu" />
    <CommonSectionMenu
      v-if="session.hasPermission(['ticket.agent', 'ticket.customer'])"
      :items="ticketOverview"
      :header-label="__('Ticket Overview')"
      :action-label="__('Edit')"
      action-link="/favorite/ticker-overviews/edit"
    >
      <template v-if="overviews.loading" #before-items>
        <div class="flex w-full justify-center">
          <CommonIcon name="loader" animation="spin" />
        </div>
      </template>
    </CommonSectionMenu>
  </div>
</template>
