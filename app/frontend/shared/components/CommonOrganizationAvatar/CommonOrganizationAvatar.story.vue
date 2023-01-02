<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonOrganizationAvatar from './CommonOrganizationAvatar.vue'
</script>

<template>
  <Story>
    <Variant title="Active">
      <CommonOrganizationAvatar
        :entity="{ name: 'Active Organization', active: true }"
        class="bg-yellow"
      />
    </Variant>
    <Variant title="Inactive">
      <CommonOrganizationAvatar
        :entity="{ name: 'Inactive Organization', active: false }"
        class="bg-yellow"
      />
    </Variant>
  </Story>
</template>
