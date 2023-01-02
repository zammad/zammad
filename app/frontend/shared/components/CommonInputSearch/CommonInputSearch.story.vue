<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { ref } from 'vue'
import CommonInputSearch from './CommonInputSearch.vue'

const textDefault = ref('Search Word')
const textNoBorder = ref('No Border On Click')
</script>

<template>
  <Story>
    <Variant title="Default">
      <CommonInputSearch v-model="textDefault" />
    </Variant>
    <Variant title="No Border">
      <CommonInputSearch v-model="textNoBorder" no-border />
    </Variant>
  </Story>
</template>
