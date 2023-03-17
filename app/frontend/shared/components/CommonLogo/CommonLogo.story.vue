<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useApplicationStore } from '@shared/stores/application'
import { h } from 'vue'
import CommonLogo from './CommonLogo.vue'

const CustomLogo = () => {
  const application = useApplicationStore()
  application.config.product_logo = 'icons/logotype.svg'
  return h(CommonLogo)
}
</script>

<template>
  <Story>
    <Variant title="Default">
      <CommonLogo />
    </Variant>
    <Variant title="Custom">
      <CustomLogo />
    </Variant>
  </Story>
</template>
