<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import NavigationMenu from '#desktop/components/NavigationMenu/NavigationMenu.vue'

import {
  personalSettingCategories,
  personalSettingItems,
} from '../views/PersonalSetting/plugins/index.ts'
</script>

<template>
  <NavigationMenu
    :categories="personalSettingCategories"
    :entries="personalSettingItems"
  />
</template>
