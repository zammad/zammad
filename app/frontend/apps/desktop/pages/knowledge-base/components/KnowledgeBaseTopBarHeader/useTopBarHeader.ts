// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useCopyToClipboard } from '#shared/composables/useCopyToClipboard.ts'

import type { TopBarHeaderProps } from './types.ts'
import type { Ref } from 'vue'

export const useTopBarHeader = (props: Ref<TopBarHeaderProps>) => {
  const { copyToClipboard } = useCopyToClipboard()

  const copyKnowledgeBaseNameToClipboard = () => {
    if (!props.value.title) return

    const anchor = document.createElement('a')
    anchor.href = document.URL
    anchor.textContent = props.value.title

    copyToClipboard([
      new ClipboardItem({
        'text/plain': props.value.title,
        'text/html': anchor.outerHTML,
      }),
    ])
  }

  return {
    copyKnowledgeBaseNameToClipboard,
  }
}
