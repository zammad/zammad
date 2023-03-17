<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { FormKit } from '@formkit/vue'
</script>

<template>
  <Story>
    <Variant title="Default">
      <FormKit type="datetime" label="Datetime" name="datetime" />
    </Variant>
  </Story>
</template>
