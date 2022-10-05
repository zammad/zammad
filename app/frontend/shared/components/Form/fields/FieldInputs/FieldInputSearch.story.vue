<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { FormKit } from '@formkit/vue'
</script>

<template>
  <Story>
    <Variant title="Default">
      <FormKit
        type="search"
        label="Search"
        name="search"
        placeholder="Search something..."
      />
    </Variant>
  </Story>
</template>
