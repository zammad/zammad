<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
defineProps<{
  width: string
  height: string
}>()
</script>

<template>
  <div
    div
    class="bg-opacity-70 absolute inset-0 flex items-center justify-center bg-black"
    :style="{
      width: width,
      height: height,
      maxWidth: '100%',
    }"
  >
    <div class="flex flex-col items-center gap-1 text-white">
      <CommonIcon name="image" />
      <CommonLabel class="text-white">{{
        $t('Failed to upload.')
      }}</CommonLabel>
    </div>
  </div>
</template>
