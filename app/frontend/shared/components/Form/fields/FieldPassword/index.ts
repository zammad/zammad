// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { cloneDeep } from 'lodash-es'
import type { FormKitNode } from '@formkit/core'
import { password as passwordDefinition } from '@formkit/inputs'
import initializeFieldDefinition from '@shared/form/core/initializeFieldDefinition'
import extendSchemaDefinition from '@shared/form/utils/extendSchemaDefinition'
import formUpdaterTrigger from '@shared/form/features/formUpdaterTrigger'

const localPasswordDefinition = cloneDeep(passwordDefinition)

const switchPasswordVisibility = (node: FormKitNode) => {
  const { props } = node

  node.addProps(['passwordVisibilityIcon'])
  props.passwordVisibilityIcon = 'mobile-show'

  extendSchemaDefinition(node, 'suffix', {
    $el: 'span',
    children: [
      {
        $cmp: 'CommonIcon',
        props: {
          name: '$passwordVisibilityIcon',
          key: node.name,
          class: 'absolute top-1/2 transform -translate-y-1/2 right-3',
          size: 'small',
          onClick: () => {
            props.type = props.type === 'password' ? 'text' : 'password'
          },
        },
      },
    ],
  })

  node.on('prop:type', ({ payload, origin }) => {
    const { props } = origin
    props.passwordVisibilityIcon =
      payload === 'password' ? 'mobile-show' : 'mobile-hide'
  })
}

initializeFieldDefinition(localPasswordDefinition, {
  features: [switchPasswordVisibility, formUpdaterTrigger('blur')],
})

export default {
  fieldType: 'password',
  definition: localPasswordDefinition,
}
