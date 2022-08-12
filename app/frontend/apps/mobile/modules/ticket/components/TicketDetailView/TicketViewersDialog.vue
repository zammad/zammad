<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonDialog from '@mobile/components/CommonDialog/CommonDialog.vue'
import CommonSectionMenu from '@mobile/components/CommonSectionMenu/CommonSectionMenu.vue'
import TicketViewerItem from './TicketViewerItem.vue'

interface Props {
  name: string
}

defineProps<Props>()
</script>

<template>
  <CommonDialog
    :name="name"
    :label="__('Ticket viewers')"
    class="w-full p-4 text-sm"
  >
    <CommonSectionMenu class="py-4" :header-label="__('Editing ticket')">
      <TicketViewerItem :user="{ id: '22', firstname: 'Sarah' }" />
    </CommonSectionMenu>
    <CommonSectionMenu class="py-4" :header-label="__('Viewing ticket')">
      <TicketViewerItem :user="{ id: '23', firstname: 'Mateo' }" />
      <TicketViewerItem :user="{ id: '24', firstname: 'Nicole' }" />
    </CommonSectionMenu>
    <CommonSectionMenu
      class="py-4"
      :header-label="__('Opened in taskbar')"
      :help="
        __(
          'Has ticket open in taskbar, but is not actively looking in the ticket.',
        )
      "
    >
      <TicketViewerItem :user="{ id: '25', firstname: 'Felix' }" />
    </CommonSectionMenu>
  </CommonDialog>
</template>
