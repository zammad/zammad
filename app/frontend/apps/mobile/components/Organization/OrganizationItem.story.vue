<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import OrganizationItem from './OrganizationItem.vue'

const organization = {
  id: '54321',
  internalId: 2,
  ticketsCount: {
    open: 2,
    closed: 0,
  },
  name: 'Lorem Ipsum',
  active: false,
}
</script>

<template>
  <Story group="modules">
    <Variant title="Default">
      <OrganizationItem
        :entity="{
          ...organization,
          active: true,
          updatedAt: new Date(2022, 1, 2).toISOString(),
          updatedBy: {
            id: '456',
            fullname: 'Jane Doe',
          },
          members: {
            edges: [
              {
                node: { fullname: 'Erik Wise' },
              },
              {
                node: { fullname: 'Peter Smith' },
              },
            ],
            totalCount: 3,
          },
        }"
      />
    </Variant>
    <Variant title="No Edit">
      <OrganizationItem :entity="organization" />
    </Variant>
  </Story>
</template>
