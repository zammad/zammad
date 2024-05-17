// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { toRef } from 'vue'

import { useLocaleStore } from '#shared/stores/locale.ts'

import type { FormKitNode } from '@formkit/core'

const formLocaleDir = (node: FormKitNode) => {
  const locale = useLocaleStore()
  const { props } = node
  node.addProps(['localeDir', 'arrowIconName'])

  props.localeDir = toRef(() => locale.localeData?.dir ?? 'ltr')
  props.arrowIconName = toRef(
    () => `chevron-${locale.localeData?.dir === 'rtl' ? 'left' : 'right'}`,
  )
}

export default formLocaleDir
