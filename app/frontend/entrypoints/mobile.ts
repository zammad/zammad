// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { registerPWAHooks } from '#shared/utils/pwa.ts'

import mountApp from '#mobile/main.ts'

registerPWAHooks()
mountApp()

// make sure the color of the address bar and iOS/Android header matches the theme
const meta =
  document.head.querySelector('meta[name="theme-color"]') ||
  document.createElement('meta')

meta.setAttribute('name', 'theme-color')
meta.setAttribute('content', '#191919')

if (!document.head.contains(meta)) {
  document.head.appendChild(meta)
}
