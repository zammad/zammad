// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { h, render, getCurrentInstance, onMounted, type VNode } from 'vue'

import getUuid from '#shared/utils/getUuid.ts'

let liveRegion: VNode | null = null
let liveRegionInnerNode: VNode | null = null

const messageNodeId = 'announcer-message'

export const useAnnouncer = () => {
  const updateMessage = (message: string) => {
    liveRegionInnerNode!.el!.innerHTML = message
  }

  const announce = (message: string) => {
    updateMessage(message)
  }

  const self = getCurrentInstance()

  const createAnnouncer = () => {
    liveRegionInnerNode = h('p', { id: messageNodeId, 'data-test-id': messageNodeId })
    liveRegion = h(
      'div',
      { ariaLive: 'polite', role: 'status', class: 'sr-only invisible', ariaRelevant: 'text' },
      [liveRegionInnerNode],
    )
    liveRegion.key = getUuid()
    liveRegion.appContext = self!.appContext

    render(liveRegion, document.querySelector('body')!)
  }

  onMounted(() => {
    if (!liveRegion) createAnnouncer()
  })

  return { announce, messageNodeId }
}
