// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { FormSchemaNode } from '@shared/components/Form'

export const defineFormSchema = (
  schema: FormSchemaNode[],
): FormSchemaNode[] => {
  const needGroup = schema.every((node) => !('isLayout' in node))
  if (!needGroup) return schema
  return [
    {
      isLayout: true,
      component: 'FormGroup',
      children: schema,
    },
  ]
}
