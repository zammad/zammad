// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { AppName } from '#shared/types/app.ts'

let appName: AppName

export const initializeAppName = (name: AppName) => {
  appName = name
}

export const useAppName = () => appName
