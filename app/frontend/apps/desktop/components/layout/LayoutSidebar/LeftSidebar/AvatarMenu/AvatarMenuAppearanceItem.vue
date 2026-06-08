<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef, useTemplateRef } from 'vue'

import CommonPopoverMenuItem, {
  type Props,
} from '#desktop/components/CommonPopoverMenu/CommonPopoverMenuItem.vue'
import ThemeSwitch from '#desktop/components/ThemeSwitch/ThemeSwitch.vue'
import { useThemeStore } from '#desktop/stores/theme.ts'

defineProps<Props>()

const themeSwitchInstance = useTemplateRef('theme-switch')

const cycleThemeSwitchValue = () => {
  themeSwitchInstance.value?.cycleValue()
}

const themeStore = useThemeStore()
const { updateTheme } = themeStore
const currentTheme = toRef(themeStore, 'currentTheme')

const modelTheme = computed({
  get: () => currentTheme.value,
  set: (theme) => updateTheme(theme),
})
</script>

<template>
  <CommonPopoverMenuItem v-bind="{ ...$props, ...$attrs }" @click="cycleThemeSwitchValue" />
  <div class="flex items-center px-2">
    <ThemeSwitch
      ref="theme-switch"
      v-model="modelTheme"
      class="hover:outline-blue-300 dark:hover:outline-blue-950"
      size="small"
    />
  </div>
</template>
