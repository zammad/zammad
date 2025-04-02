// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

export type BadgeSize = 'xs' | 'small' | 'medium' | 'large' | 'xl'

export type BadgeVariant =
  | 'success'
  | 'info'
  | 'warning'
  | 'danger'
  | 'neutral'
  | 'tertiary'
  | 'custom'

export type BadgeClass = BadgeVariant | 'base'
export type BadgeClassMap = Record<BadgeClass, string>
