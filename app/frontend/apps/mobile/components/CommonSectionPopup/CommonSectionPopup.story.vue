<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { ref } from 'vue'
import CommonSectionPopup from './CommonSectionPopup.vue'

const state = ref(false)
// eslint-disable-next-line no-alert
const alert = (msg: string) => window.alert(msg)
</script>

<template>
  <Story>
    <Variant title="Default">
      <button @click="state = true">Open Popup</button>
      <CommonSectionPopup
        v-model:state="state"
        :items="[
          {
            label: 'Some Item',
            onAction() {
              alert('clicked!')
            },
          },
          {
            label: 'Some Link',
            link: '/',
          },
        ]"
      />
    </Variant>
  </Story>
</template>
