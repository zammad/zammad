// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { FormSchemaNode } from '#shared/components/Form/types.ts'
import { EnumObjectManagerObjects } from '#shared/graphql/types.ts'

export const useUserFormSchema = () => {
  const buildUserSchema = (screen: 'edit' | 'create', schema?: FormSchemaNode[]) => [
    {
      screen,
      object: EnumObjectManagerObjects.User,
    },
    ...(schema ? schema : []),
  ]

  return {
    buildUserSchema,
  }
}
