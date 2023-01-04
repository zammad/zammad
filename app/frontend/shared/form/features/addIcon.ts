// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { FormKitNode } from '@formkit/core'
import { FormSchemaExtendType } from '@shared/types/form'
import extendSchemaDefinition from '../utils/extendSchemaDefinition'

const addIcon = (node: FormKitNode) => {
  node.addProps(['iconPosition', 'icon', 'onIconClick'])

  if (
    !node.props.definition ||
    typeof node.props.definition.schema !== 'function'
  ) {
    return
  }

  const iconPosition = node.props.iconPosition || 'prefix'

  const initalizeIconClickHandler = () => {
    if (!node.props.icon) return

    if (node.context && node.props.onIconClick) {
      node.context.onIconClick = node.props.onIconClick

      const iconClick = () => {
        if (typeof node.context?.onIconClick === 'function') {
          node.context.onIconClick(node)
        }
      }
      node.context.handleIconClick = iconClick.bind(null)
    }
  }

  node.on('created', () => {
    initalizeIconClickHandler()
  })

  extendSchemaDefinition(
    node,
    iconPosition,
    {
      if: '$icon',
      $el: 'span',
      children: [
        {
          $cmp: 'CommonIcon',
          props: {
            name: '$icon',
            key: node.name,
            class: `absolute top-1/2 transform -translate-y-1/2 ${
              iconPosition === 'prefix' ? 'left-3' : 'right-3'
            }`,
            size: 'small',
            onClick: {
              if: '$onIconClick',
              then: `$handleIconClick`,
            },
          },
        },
      ],
    },
    FormSchemaExtendType.Prepend,
  )
}

export default addIcon
