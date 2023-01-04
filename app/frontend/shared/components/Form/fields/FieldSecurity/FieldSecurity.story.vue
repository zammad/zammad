<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { FormKit } from '@formkit/vue'
import FormGroup from '../../FormGroup.vue'
</script>

<template>
  <Story>
    <Variant title="Allow all">
      <FormGroup>
        <FormKit
          type="security"
          label="Security"
          :allowed="['encryption', 'sign']"
        />
      </FormGroup>
    </Variant>
    <Variant title="Allow none">
      <FormGroup>
        <FormKit type="security" label="Security" :allowed="[]" />
      </FormGroup>
    </Variant>
  </Story>
</template>
