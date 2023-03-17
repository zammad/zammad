<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { FormKit } from '@formkit/vue'

const variants = {
  true: 'yes',
  false: 'no',
}
</script>

<template>
  <Story>
    <Variant title="Default">
      <FormKit
        type="toggle"
        label="Toggle"
        name="toggle"
        :variants="variants"
      />
    </Variant>
  </Story>
</template>
