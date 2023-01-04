<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonDateTime from './CommonDateTime.vue'
</script>

<template>
  <Story>
    <Variant title="Absolute Time">
      <CommonDateTime
        date-time="2020-10-10 10:10:11"
        type="absolute"
        absolute-format="date"
      />
    </Variant>
    <Variant title="Relative Time">
      <CommonDateTime date-time="2020-10-10 10:10:11" type="relative" />
    </Variant>
  </Story>
</template>
