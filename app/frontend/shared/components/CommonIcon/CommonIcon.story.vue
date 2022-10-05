<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import 'virtual:svg-icons-register' // eslint-disable-line import/no-unresolved
import icons from 'virtual:svg-icons-names' // eslint-disable-line import/no-unresolved
import { ref } from 'vue'
import CommonIcon from './CommonIcon.vue'

const klass = ref('')
</script>

<template>
  <Story
    title="Icons"
    icon="uil:image-v"
    group="design-system"
    :layout="{ type: 'grid', width: '100px' }"
  >
    <template #controls>
      <HstText v-model="klass" title="Class" />
    </template>

    <Variant v-for="iconName of icons" :key="iconName" :title="iconName">
      <CommonIcon
        :name="iconName.slice('icon-'.length)"
        :class="klass"
        size="small"
      />
    </Variant>
  </Story>
</template>
