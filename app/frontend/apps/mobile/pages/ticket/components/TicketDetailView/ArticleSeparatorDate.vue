<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
interface Props {
  date: string
}

defineProps<Props>()
</script>

<template>
  <div class="text-gray text-center">
    <CommonDateTime :date-time="date" type="absolute" absolute-format="date" />
  </div>
</template>
