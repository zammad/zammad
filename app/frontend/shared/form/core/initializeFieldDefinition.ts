// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { FormKitTypeDefinition } from '@formkit/core'
import type { FormKitSchemaExtendableSection } from '@formkit/inputs'
import { mergeArray } from '#shared/utils/helpers.ts'
import {
  outer,
  inner,
  wrapper,
  icon,
  help,
  messages,
  message,
  prefix,
  suffix,
  label,
} from '@formkit/inputs'
import { block } from '../sections/block.ts'
import { arrow } from '../sections/arrow.ts'
import { link } from '../sections/link.ts'
import defaulfFieldDefinition from './defaultFieldDefinition.ts'

export interface FieldsCustomOptions {
  addDefaultProps?: boolean
  addDefaultFeatures?: boolean
  addArrow?: boolean
  schema?: () => FormKitSchemaExtendableSection
}

const initializeFieldDefinition = (
  definition: FormKitTypeDefinition,
  additionalDefinitionOptions: Pick<
    FormKitTypeDefinition,
    'props' | 'features'
  > = {},
  options: FieldsCustomOptions = {},
) => {
  const {
    addDefaultProps = true,
    addDefaultFeatures = true,
    addArrow = false,
  } = options

  const localDefinition = definition
  localDefinition.props = Array.isArray(localDefinition.props)
    ? localDefinition.props
    : []
  localDefinition.features ||= []

  if (options.schema) {
    const wrapperSchema = wrapper(
      label('$label'),
      inner(
        icon('prefix', 'label'),
        prefix(),
        options.schema(),
        suffix(),
        icon('suffix'),
      ),
    )
    const blockSchema = [wrapperSchema]

    if (addArrow) {
      blockSchema.push(arrow())
    }

    blockSchema.push(link())

    localDefinition.schema = outer(
      block(...blockSchema),
      help('$help'),
      messages(message('$message.value')),
    )
  }

  const additionalProps = Array.isArray(additionalDefinitionOptions.props)
    ? additionalDefinitionOptions.props
    : []
  if (addDefaultProps) {
    const defaulfFieldDefinitionProps = Array.isArray(
      defaulfFieldDefinition.props,
    )
      ? defaulfFieldDefinition.props
      : []

    localDefinition.props = mergeArray(
      localDefinition.props,
      defaulfFieldDefinitionProps.concat(additionalProps),
    )
  }

  const additionalFeatures = additionalDefinitionOptions.features || []
  if (addDefaultFeatures) {
    localDefinition.features = mergeArray(
      defaulfFieldDefinition.features.concat(additionalFeatures),
      localDefinition.features,
    )
  }
}

export default initializeFieldDefinition
