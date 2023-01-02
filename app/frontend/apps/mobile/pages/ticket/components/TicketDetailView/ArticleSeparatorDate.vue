<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
interface Props {
  date: string
}

defineProps<Props>()
</script>

<template>
  <div class="text-center text-gray">
    <CommonDateTime :date-time="date" type="absolute" absolute-format="date" />
  </div>
</template>
