// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

export interface SystemSetupManual {
  setTitle: (title: string) => void
}

export interface SystemInformationData {
  organization: string
  logo: string
  url: string
  localeDefault: string
  timezoneDefault: string
}
