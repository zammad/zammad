// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { FormSchemaNode } from '@shared/components/Form'

export function defineFormSchema(schema: FormSchemaNode[]): FormSchemaNode[] {
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
