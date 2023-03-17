<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonFilePreview from './CommonFilePreview.vue'

const file = {
  name: 'test file.txt',
  type: 'text/plain',
  size: 12343,
}
</script>

<template>
  <Story>
    <CommonFilePreview :file="file" download-url="/" />
  </Story>
</template>
