<script setup lang="ts">
// This starter template is using Vue 3 <script setup> SFCs
// Check out https://v3.vuejs.org/api/sfc-script-setup.html#sfc-script-setup

import { ref } from 'vue'
import CommonHelloWorld from '@common/components/CommonHelloWorld.vue'

const state = ref<boolean>(false)
</script>

<template>
  <input v-model="state" type="checkbox" /> Show output?
  <CommonHelloWorld msg="Zammad Mobile!" :show="state" />
</template>

<style>
#app {
  font-family: Avenir, Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-align: center;
  color: #2c3e50;
  margin-top: 60px;
}
</style>
