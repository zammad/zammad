<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
interface Props {
  date: string
}

defineProps<Props>()
</script>

<template>
  <div class="text-center text-gray">
    <time role="time" :datetime="date">{{ date }}</time>
  </div>
</template>
