// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { toRef, toValue, type MaybeRefOrGetter } from 'vue'

import { useCopyToClipboard } from '#shared/composables/useCopyToClipboard.ts'
import type { KeyboardShortcutOptions } from '#shared/composables/useKeyboardShortcut/types.ts'
import { useKeyboardShortcut } from '#shared/composables/useKeyboardShortcut/useKeyboardShortcut.ts'
import { useApplicationStore } from '#shared/stores/application.ts'

export interface ObjectReference {
  number?: string
  title?: string
  // A route of the desktop view, e.g. `/users/2`.
  path?: string
}

/**
 * Copies more of the shown object the more often `.` is pressed in a row, like the old desktop
 *   view: the number, then with the title, then with the link as well. An object without a number
 *   is referenced by its title alone, and nothing is copied where there is nothing to reference.
 */
export const useObjectReferenceShortcut = (
  reference: MaybeRefOrGetter<ObjectReference | undefined>,
  options: Pick<KeyboardShortcutOptions, 'enabled'> = {},
) => {
  const config = toRef(useApplicationStore(), 'config')

  const { copyToClipboard } = useCopyToClipboard()

  const createLinkItem = (label: string, url: string, number?: string, title?: string) => {
    const anchor = document.createElement('a')
    anchor.href = url
    anchor.textContent = number || title || ''

    const html = document.createElement('div')
    html.append(anchor)
    if (number && title) html.append(`: ${title}`)

    return new ClipboardItem({
      'text/plain': `${label}\n${url}`,
      'text/html': html.innerHTML,
    })
  }

  const copyObjectReference = (count: number) => {
    const { number, title, path } = toValue(reference) ?? {}

    if (count <= 1) {
      if (number) copyToClipboard(number)
      return
    }

    const label = [number, title].filter(Boolean).join(': ')
    if (!label) return

    if (count === 2) {
      copyToClipboard(label)
      return
    }

    if (count > 3 || !path) return

    const url = `${config.value.http_type}://${config.value.fqdn}/desktop${path}`

    copyToClipboard([createLinkItem(label, url, number, title)])
  }

  useKeyboardShortcut('copy-object-number', ({ count }) => copyObjectReference(count), {
    ...options,
    onlyOutsideInputs: true,
  })
}
