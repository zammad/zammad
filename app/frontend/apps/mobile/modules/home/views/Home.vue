<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { MenuItem } from '@mobile/components/CommonSectionMenu'
import CommonSectionMenu from '@mobile/components/CommonSectionMenu/CommonSectionMenu.vue'
import CommonInputSearch from '@shared/components/CommonInputSearch/CommonInputSearch.vue'

const IS_DEV = import.meta.env.DEV

// TODO all menus should be generated on back-end
const menu: MenuItem[] = [
  {
    type: 'link',
    link: '/tickets',
    title: __('All Tickets'),
    icon: { name: 'stack', size: 'base' },
    iconBg: 'bg-pink',
  },
  // cannot inline import.meta here, Vite fails
  ...(IS_DEV
    ? [
        {
          type: 'link' as const,
          link: '/playground',
          title: 'Playground',
          icon: { name: 'cog', size: 'small' as const },
          iconBg: 'bg-orange',
        },
      ]
    : []),
]

const ticketOverview: MenuItem[] = [
  {
    type: 'link',
    link: '/tickets',
    title: __('My Assigned Tickets'),
    information: '2',
  },
  {
    type: 'link',
    link: '/tickets',
    title: __('Unassigned & Open Tickets'),
    information: '3',
  },
  {
    type: 'link',
    link: '/tickets',
    title: __('My Pending Reached Tickets'),
    information: '2',
  },
  {
    type: 'link',
    link: '/tickets',
    title: __('My Subscribed Tickets'),
    information: '1',
  },
]

const openSearchDialog = () => {
  console.log('open dialog')
}
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
      {{ i18n.t('Home') }}
    </div>
    <CommonInputSearch
      wrapper-class="mb-4"
      no-border
      @click="openSearchDialog"
    />
    <CommonSectionMenu :items="menu" />
    <CommonSectionMenu
      :items="ticketOverview"
      :header-title="__('Ticket Overview')"
      :action-title="__('Edit')"
    />
  </div>
</template>
