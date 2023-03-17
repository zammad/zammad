<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonLink from './CommonLink.vue'
</script>

<template>
  <Story title="CommonLink">
    <Variant title="Basic">
      <CommonLink link="https://www.google.com">A test Link</CommonLink>
    </Variant>
    <Variant title="External">
      <CommonLink link="https://www.google.com" is-external open-in-new-tab>
        A test Link
      </CommonLink>
    </Variant>
    <Variant title="Router">
      <CommonLink link="/login" is-route> A test Link </CommonLink>
    </Variant>
    <Variant title="Disabled">
      <CommonLink link="/login" disabled> A test Link </CommonLink>
    </Variant>
  </Story>
</template>
