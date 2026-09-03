// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { getCurrentInstance, h, onMounted, render, type AppContext, type VNode } from 'vue'

const messageNodeId = 'announcer-message'

// There is one live region for the whole app, and this module scope is what makes it one: several
//   components announce into it, and `messageNodeId` is what their `aria-describedby` points at, so
//   a second region would both split the announcements and duplicate the id.
let container: HTMLElement | null = null
let messageNode: VNode | null = null
let appContext: AppContext | null = null

let pendingMessage: ReturnType<typeof setTimeout> | null = null

// Screen readers only pick up a mutation of a live region that was already in the accessibility tree
//   when it happened. Inserting the region and writing the message in the same frame is dropped
//   silently, hence the delay before every message — including the first one, which usually follows
//   the region's creation closely.
const ANNOUNCE_DELAY = 100

const messageElement = () => messageNode?.el as HTMLElement | undefined

const destroyAnnouncer = () => {
  if (!container) return

  render(null, container)
  container.remove()

  container = null
  messageNode = null
}

const createAnnouncer = () => {
  // Nothing is ever rendered next to an existing region: whatever is left over goes first, so there
  //   is exactly one at any time.
  destroyAnnouncer()

  container = document.createElement('div')
  document.body.appendChild(container)

  messageNode = h('p', { id: messageNodeId, 'data-test-id': messageNodeId })

  const liveRegion = h(
    'div',
    {
      role: 'status',
      // Written in their attribute form on purpose: the camelCase variants only reach the DOM where
      //   the browser reflects ARIA properties, and end up as a meaningless `arialive` attribute
      //   everywhere else.
      'aria-live': 'polite',
      'aria-atomic': 'true',
      // The message node's text is replaced wholesale, which is a removal plus an addition —
      //   `additions text` covers both, `text` alone does not.
      'aria-relevant': 'additions text',
      class: 'sr-only',
    },
    [messageNode],
  )

  if (appContext) liveRegion.appContext = appContext

  render(liveRegion, container)
}

// The region is a singleton, but the document it lives in is not: a remounted app (or a test tearing
//   down `document.body`) leaves this module holding a detached node, and everything announced into
//   it goes nowhere. Asking the element whether it is still connected — rather than only whether we
//   ever built one — rebuilds it in that case.
const ensureAnnouncer = () => {
  if (!messageElement()?.isConnected) createAnnouncer()
}

export const useAnnouncer = () => {
  // Kept for the region's own render, so it stays part of the app it was first used from.
  appContext ??= getCurrentInstance()?.appContext ?? null

  const announce = (message: string) => {
    ensureAnnouncer()

    // A live region does not announce an update that leaves its content unchanged, so the same
    //   message twice in a row would be read once. Clearing first makes the write a real change
    //   every time.
    messageElement()!.textContent = ''

    // Only the latest message is worth reading: a queued one that never got announced is already
    //   outdated by the time it would be.
    if (pendingMessage) clearTimeout(pendingMessage)

    pendingMessage = setTimeout(() => {
      pendingMessage = null

      const element = messageElement()
      if (element?.isConnected) element.textContent = message
    }, ANNOUNCE_DELAY)
  }

  // Built up front where possible, so the region is in the accessibility tree well before the first
  //   message, and so `aria-describedby="messageNodeId"` resolves for the components referencing it.
  //   `announce` builds it on demand too, which is what makes this composable usable outside a
  //   component as well.
  if (getCurrentInstance()) onMounted(ensureAnnouncer)

  return { announce, messageNodeId }
}
