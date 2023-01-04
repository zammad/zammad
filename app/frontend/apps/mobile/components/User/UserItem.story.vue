<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import UserItem from './UserItem.vue'

const user = {
  id: '123',
  ticketsCount: {
    open: 2,
    closed: 0,
  },
  firstname: 'John',
  lastname: 'Doe',
  organization: {
    name: 'organization',
  },
}
</script>

<template>
  <Story group="modules">
    <Variant title="Default">
      <UserItem
        :entity="{
          ...user,
          updatedAt: new Date(2022, 1, 2).toISOString(),
          updatedBy: {
            id: '456',
            fullname: 'Jane Doe',
          },
        }"
      />
    </Variant>
    <Variant title="No Edit">
      <UserItem :entity="user" />
    </Variant>
  </Story>
</template>
