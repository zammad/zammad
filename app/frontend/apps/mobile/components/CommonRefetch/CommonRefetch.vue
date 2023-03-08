<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { ref, watch } from 'vue'
import CommonLoader from '../CommonLoader/CommonLoader.vue'

const props = defineProps<{
  refetch: boolean
}>()

const refetching = ref(false)

let timeout: number

watch(
  () => props.refetch,
  (status) => {
    if (status) {
      timeout = window.setTimeout(() => {
        refetching.value = true
      }, 250)
    } else {
      window.clearTimeout(timeout)
      refetching.value = false
    }
  },
)
</script>

<template>
  <CommonLoader :loading="refetching" class="absolute">
    <slot />
  </CommonLoader>
</template>
