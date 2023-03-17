// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

let appName: string

export const initializeAppName = (name: string) => {
  appName = name
}

export const useAppName = () => appName
