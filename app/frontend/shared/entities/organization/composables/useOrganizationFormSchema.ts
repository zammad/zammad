// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { FormSchemaNode } from '#shared/components/Form/types.ts'
import { EnumObjectManagerObjects } from '#shared/graphql/types.ts'

export const useOrganizationFormSchema = () => {
  const buildOrganizationSchema = (screen: 'edit' | 'create', schema?: FormSchemaNode[]) => [
    {
      screen,
      object: EnumObjectManagerObjects.Organization,
    },
    ...(schema ? schema : []),
  ]

  return {
    buildOrganizationSchema,
  }
}
