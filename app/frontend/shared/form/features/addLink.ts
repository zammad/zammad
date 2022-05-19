// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { cloneDeep } from 'lodash-es'
import { FormKitNode, FormKitExtendableSchemaRoot } from '@formkit/core'

export const externalLinkClass =
  'flex justify-center items-center p-2 rounded-xl border-none focus:outline-none bg-gray-500 ml-2 w-14 h-14'

interface AddLinkExtensionOptions {
  class?: string
}

const addLink = (settings?: AddLinkExtensionOptions) => (node: FormKitNode) => {
  const { props } = node

  if (!props.definition) return

  node.addProps(['link'])

  const definition = cloneDeep(props.definition)

  const originalSchema = definition.schema as FormKitExtendableSchemaRoot

  definition.schema = (extensions) => {
    const localExtensions = {
      ...extensions,
      suffix: {
        $el: 'div',
        if: '$link',
        attrs: {
          class: settings?.class,
        },
        children: [
          {
            $cmp: 'CommonLink',
            props: {
              link: '$link',
              openInNewTab: true,
              class: externalLinkClass,
            },
            children: [
              {
                $cmp: 'CommonIcon',
                props: {
                  name: 'external',
                  size: 'small',
                },
              },
            ],
          },
        ],
      },
    }
    return originalSchema(localExtensions)
  }

  props.definition = definition
}

export default addLink
