// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { EnumSecurityStateType } from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n.ts'

export const translateArticleSecurity = (security: string) => {
  const typeLabels = {
    [EnumSecurityStateType.Pgp]: __('PGP'),
    [EnumSecurityStateType.Smime]: __('S/MIME'),
  } as Record<string, string>

  return i18n.t(typeLabels[security] || security)
}
