// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { FormSchemaNode } from '#shared/components/Form/types.ts'

type FormSchemaOptions = {
  showDirtyMark: boolean
}

export const defineFormSchema = (
  schema: FormSchemaNode[],
  options?: FormSchemaOptions,
): FormSchemaNode[] => {
  const needGroup = schema.every(
    (node) => !(typeof node !== 'string' && 'isLayout' in node),
  )

  if (!needGroup) return schema
  return [
    {
      isLayout: true,
      component: 'FormGroup',
      props: options,
      children: schema,
    },
  ]
}
