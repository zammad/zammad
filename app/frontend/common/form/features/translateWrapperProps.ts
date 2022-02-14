// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { i18n } from '@common/utils/i18n'
import type { FormKitNode } from '@formkit/core'
import { isEmpty } from 'lodash-es'
import { computed, ComputedRef } from 'vue'

interface TranslateableProps {
  label?: ComputedRef<string>
  help?: ComputedRef<string>
  placeholder?: ComputedRef<string>
}

interface TranslatedAttrs {
  placeholder?: ComputedRef<string>
}

export default function translateWrapperProps(node: FormKitNode): void {
  node.on('created', () => {
    const { props, context } = node
    const { label, labelPlaceholder, help, placeholder } = props

    const translatedProps: TranslateableProps = {}

    if (label) {
      const labelComputed = computed(() => {
        return i18n.t(label, ...(labelPlaceholder || []))
      })

      translatedProps.label = labelComputed
    }

    if (help) {
      const helpComputed = computed(() => {
        return i18n.t(help)
      })
      translatedProps.help = helpComputed
    }

    const translatedAttrs: TranslatedAttrs = {}

    if (placeholder) {
      translatedProps.placeholder = computed(() => i18n.t(placeholder))
    } else if (props.attrs && props.attrs.placeholder) {
      translatedAttrs.placeholder = computed(() =>
        i18n.t(props.attrs.placeholder),
      )
    }

    Object.assign(node.props, translatedProps)

    if (!isEmpty(translatedAttrs) && context) {
      context.attrs = {
        ...node.props.attrs,
        ...translatedAttrs,
      }
    }
  })
}
