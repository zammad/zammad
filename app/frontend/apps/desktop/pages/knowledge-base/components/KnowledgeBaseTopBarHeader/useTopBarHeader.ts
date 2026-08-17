// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import {
  createLinkClipboardItem,
  useCopyToClipboard,
} from '#shared/composables/useCopyToClipboard.ts'

import type { TopBarHeaderProps } from './types.ts'
import type { Ref } from 'vue'

export const useTopBarHeader = (props: Ref<TopBarHeaderProps>) => {
  const { copyToClipboard } = useCopyToClipboard()

  const copyKnowledgeBaseNameToClipboard = () => {
    if (!props.value.title) return

    copyToClipboard([createLinkClipboardItem(document.URL, props.value.title)])
  }

  return {
    copyKnowledgeBaseNameToClipboard,
  }
}
