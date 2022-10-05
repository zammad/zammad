<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { FormKit } from '@formkit/vue'
import { CheckboxVariant } from './types'
</script>

<template>
  <Story>
    <Variant title="Default">
      <FormKit type="checkbox" label="Checkbox" name="checkbox" />
    </Variant>
    <Variant title="Switch">
      <FormKit
        type="checkbox"
        label="Checkbox"
        name="checkbox"
        :variant="CheckboxVariant.Switch"
      />
    </Variant>
  </Story>
</template>
