// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { defineStore } from 'pinia'

import { useLastVisitedPath } from '#desktop/composables/useLastVisitedPath.ts'

export const usePersonalSettingStore = defineStore('personalSetting', () => {
  const { previousPath, rememberPath } = useLastVisitedPath('/personal-setting/appearance')

  return {
    previousPersonalSettingPath: previousPath,
    setPreviousPersonalSettingScreen: rememberPath,
  }
})
