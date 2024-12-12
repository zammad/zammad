// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { defineStore } from 'pinia'
import { ref } from 'vue'

export const usePersonalSettingStore = defineStore('personalSetting', () => {
  const previousPersonalSettingPath = ref('/personal-setting/appearance')

  const setPreviousPersonalSettingScreen = (path: string) => {
    previousPersonalSettingPath.value = path
  }

  return {
    previousPersonalSettingPath,
    setPreviousPersonalSettingScreen,
  }
})
