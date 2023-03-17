<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import LayoutHeader from './LayoutHeader.vue'

const onAction = () => {
  // eslint-disable-next-line no-alert
  alert('Hello, World!')
}
</script>

<template>
  <Story>
    <Variant title="Default">
      <LayoutHeader title="Custom Title" />
    </Variant>
    <Variant title="With Back Button">
      <LayoutHeader title="Custom Title" back-title="Back" back-url="/" />
    </Variant>
    <Variant title="With Action">
      <LayoutHeader
        title="Custom Title"
        action-title="Action"
        @action="onAction"
      />
    </Variant>
    <Variant title="Full Header">
      <LayoutHeader
        title="Custom Title"
        back-title="Back"
        back-url="/"
        action-title="Action"
        @action="onAction"
      />
    </Variant>
  </Story>
</template>
