<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useRouter } from 'vue-router'
import useAuthenticationStore from '@shared/stores/authentication'
import { useNotifications } from '@shared/components/CommonNotifications'
import { MenuItem } from '@mobile/components/CommonSectionMenu'
import CommonSectionMenu from '@mobile/components/CommonSectionMenu/CommonSectionMenu.vue'
import Form from '@shared/components/Form/Form.vue'
import { FormSchemaNode } from '@shared/components/Form'

const schema: FormSchemaNode[] = [
  {
    type: 'text',
    name: 'input',
    label: 'Some_Input',
    props: {
      link: '/tickets',
    },
  },
  {
    type: 'tel',
    name: 'input2',
    props: {
      link: '/tickets',
    },
    label: 'Another_Input',
  },
  {
    type: 'date',
    name: 'date',
    label: 'Date_Input',
    props: {
      link: '/tickets',
    },
  },
  {
    type: 'select',
    name: 'select',
    label: 'Select',
    props: {
      link: '/tickets',
      options: [{ label: 'Label', value: 1 }],
    },
  },
  {
    type: 'treeselect',
    name: 'treeselect',
    label: 'Treeselect',
    props: {
      options: [{ label: 'Label', value: 1 }],
      link: '/tickets',
    },
  },
]

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
</script>

<template>
  <div class="pt-10">
    <div class="p-4">
      <Form :schema="schema" />
    </div>
    <div class="flex w-full items-center justify-center text-3xl font-bold">
      {{ i18n.t('Home') }}
    </div>
    <CommonSectionMenu :items="menu" action-title="Edit" />
    <CommonSectionMenu
      :items="ticketOverview"
      header-title="Ticket overviews"
      action-title="Edit"
    />
    <CommonSectionMenu :items="logoutMenu" />
  </div>
</template>
