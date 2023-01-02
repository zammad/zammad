<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { ref } from 'vue'
import CommonSelect from './CommonSelect.vue'

const options = [
  {
    value: 0,
    label: 'Item A',
  },
  {
    value: 1,
    label: 'Item B',
  },
  {
    value: 2,
    label: 'Item C',
  },
]

const modelValue = ref()
</script>

<template>
  <Story>
    <Variant title="Default">
      <CommonSelect #default="{ open }" v-model="modelValue" :options="options">
        <button @click="open">Click Me!</button>
        <div>Selected: {{ modelValue }}</div>
      </CommonSelect>
    </Variant>
    <Variant title="Multiple">
      <CommonSelect
        #default="{ open }"
        v-model="modelValue"
        multiple
        :options="options"
      >
        <button @click="open">Click Me!</button>
        <div>Selected: {{ modelValue }}</div>
      </CommonSelect>
    </Variant>
  </Story>
</template>
