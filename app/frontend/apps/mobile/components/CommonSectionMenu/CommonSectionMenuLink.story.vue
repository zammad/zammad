<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonSectionMenuLink from './CommonSectionMenuLink.vue'

const alert = window.alert?.bind
</script>

<template>
  <Story>
    <Variant title="Default">
      <CommonSectionMenuLink
        link="/"
        icon="mobile-home"
        information="33"
        label="Home"
      />
    </Variant>
    <Variant title="Action">
      <CommonSectionMenuLink label="Clik Me" @click="alert('Hello World')" />
    </Variant>
  </Story>
</template>
