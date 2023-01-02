<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { TicketState } from '@shared/entities/ticket/types'
import TicketItem from './TicketItem.vue'

const ticket = {
  id: '54321',
  internalId: 1,
  number: '12345',
  state: { name: TicketState.Open },
  title: 'Test Ticket',
  owner: {
    fullname: 'Jane Doe',
  },
}
</script>

<template>
  <Story title="TicketItem" group="modules">
    <Variant title="Default">
      <TicketItem
        :entity="{
          ...ticket,
          updatedAt: new Date(2022, 1, 2).toISOString(),
          updatedBy: {
            id: '456',
            fullname: 'Jane Doe',
          },
          priority: {
            name: 'HIGH',
            defaultCreate: false,
          },
        }"
      />
    </Variant>

    <Variant title="No Edit">
      <TicketItem :entity="ticket" />
    </Variant>
  </Story>
</template>
