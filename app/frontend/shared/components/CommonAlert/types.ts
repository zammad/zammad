// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

export type AlertVariant = 'success' | 'info' | 'warning' | 'danger'
export type AlertClass = AlertVariant | 'base'
export type AlertClassMap = Record<AlertClass, string>
