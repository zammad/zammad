<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useRouter } from 'vue-router'
import useAuthenticationStore from '@shared/stores/authentication'
import { useNotifications } from '@shared/components/CommonNotifications'
import { MenuItem } from '@mobile/components/CommonSectionMenu'
import CommonSectionMenu from '@mobile/components/CommonSectionMenu/CommonSectionMenu.vue'

const menu: MenuItem[] = [
  { type: 'link', link: '/tickets', title: __('All Tickets') },
  { type: 'link', link: '/', title: __('Knowledge Base') },
  { type: 'link', link: '/', title: __('Chat'), information: '1' },
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

const { clearAllNotifications } = useNotifications()
const authentication = useAuthenticationStore()
const router = useRouter()

const logoutMenu: MenuItem[] = [
  {
    type: 'link',
    onClick() {
      clearAllNotifications()
      authentication.logout().then(() => {
        router.push('/login')
      })
    },
    title: __('Logout'),
  },
]

const testingMenu: MenuItem[] = [
  {
    type: 'link',
    link: '/playground',
    title: 'Playground',
  },
]
</script>

<template>
  <div class="pt-10">
    <div class="flex w-full items-center justify-center text-3xl font-bold">
      {{ i18n.t('Home') }}
    </div>
    <CommonSectionMenu :items="testingMenu" />
    <CommonSectionMenu :items="menu" action-title="Edit" />
    <CommonSectionMenu
      :items="ticketOverview"
      header-title="Ticket overviews"
      action-title="Edit"
    />
    <CommonSectionMenu :items="logoutMenu" />
  </div>
</template>
