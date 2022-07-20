// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { i18n } from '@shared/i18n'
import type { FormKitNode } from '@formkit/core'
import { createMessage } from '@formkit/core'
import { isEmpty } from 'lodash-es'
import type { ComputedRef } from 'vue'
import { computed } from 'vue'

const propsToTranslate = ['label', 'placeholder', 'help']
const attrsToTranslate = ['placeholder']

const translateAttrs = (node: FormKitNode, attrs: Record<string, string>) => {
  const translatedAttrs: Record<string, string | ComputedRef<string>> = {
    ...attrs,
  }

  attrsToTranslate.forEach((attr) => {
    if (
      attr in attrs &&
      (!node.store[attr] || node.store[attr].value !== attrs[attr])
    ) {
      // Remember the source message.
      node.store.set(
        createMessage({
          key: attr,
          type: 'ui',
          value: attrs[attr] as string,
        }),
      )
    }

    if (node.store[attr] && node.store[attr].value) {
      translatedAttrs.placeholder = computed(() => {
        return i18n.t(node.store.placeholder.value as string)
      })
    }
  })

  return translatedAttrs
}

const translateWrapperProps = (node: FormKitNode) => {
  node.hook.prop(({ prop, value }, next) => {
    const propName = prop as string
    if (propName === 'attrs' && !isEmpty(value)) {
      value = translateAttrs(node, value)
    }
    if (propsToTranslate.includes(propName)) {
      if (!node.store[propName] || node.store[propName].value !== value) {
        node.store.set(
          createMessage({
            key: propName,
            type: 'ui',
            value,
          }),
        )
      }

      if (propName === 'label') {
        value = computed(() => {
          return i18n.t(
            node.store[propName].value as string,
            ...(node.props.labelPlaceholder || []),
          )
        })
      } else {
        value = computed(() => {
          return i18n.t(node.store[propName].value as string)
        })
      }
    }
    return next({ prop, value })
  })

  // Trigger hooks for props that were already set (at the moment more a hack, will be improvd in FormKit).
  node.on('created', () => {
    propsToTranslate.forEach((prop) => {
      if (prop in node.props) {
        // eslint-disable-next-line no-self-assign
        node.props[prop] = node.props[prop]
      }
    })
  })
}

export default translateWrapperProps
