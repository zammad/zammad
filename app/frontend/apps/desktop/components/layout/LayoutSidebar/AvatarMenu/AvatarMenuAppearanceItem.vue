<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { ref } from 'vue'

import CommonPopoverMenuItem, {
  type Props,
} from '#desktop/components/CommonPopover/CommonPopoverMenuItem.vue'
import ThemeSwitch from '#desktop/components/ThemeSwitch/ThemeSwitch.vue'
import type { ThemeSwitchInstance } from '#desktop/components/ThemeSwitch/types.ts'
import { useThemeUpdate } from '#desktop/pages/personal-setting/composables/useThemeUpdate.ts'

defineProps<Props>()

const themeSwitch = ref<ThemeSwitchInstance>()

const cycleThemeSwitchValue = () => {
  themeSwitch.value?.cycleValue()
}

const { currentTheme } = useThemeUpdate()
</script>

<template>
  <CommonPopoverMenuItem
    v-bind="{ ...$props, ...$attrs }"
    @click="cycleThemeSwitchValue"
  />
  <div class="flex items-center px-2">
    <ThemeSwitch
      ref="themeSwitch"
      v-model="currentTheme"
      class="hover:outline-blue-300 focus:outline-blue-600 hover:focus:outline-blue-600 dark:hover:outline-blue-950 dark:focus:outline-blue-900 dark:hover:focus:outline-blue-900"
      size="small"
    />
  </div>
</template>
