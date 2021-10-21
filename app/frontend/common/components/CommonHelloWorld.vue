<script setup lang="ts">
import { ref } from 'vue'

defineProps<{ msg: string; show: boolean }>()

const count = ref(0)
</script>

<template>
  <div v-if="show">
    <h1>{{ msg }}</h1>
    <p>The first component.</p>
  </div>
</template>
