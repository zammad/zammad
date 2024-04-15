<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { ref, watch } from 'vue'

const props = defineProps<{
  refetch: boolean
}>()

defineOptions({ inheritAttrs: false })

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
  <Transition
    enter-active-class="transition-opacity duration-200"
    leave-active-class="transition-opacity duration-200"
    enter-from-class="opacity-0"
    leave-to-class="opacity-0"
  >
    <div
      v-if="refetching"
      v-bind="$attrs"
      class="absolute items-center justify-center"
      role="status"
    >
      <CommonIcon
        :label="__('Loading content')"
        name="loading"
        animation="spin"
      />
    </div>
    <div v-else v-bind="$attrs">
      <slot />
    </div>
  </Transition>
</template>
