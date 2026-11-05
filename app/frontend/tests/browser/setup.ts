// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { beforeAll, beforeEach } from 'vitest'
import { commands } from 'vitest/browser'

import '#mobile/styles/main.css'
import '#shared/components/CommonIcon/injectIcons.ts'
import '../../../../public/assets/frontend/fonts.css'

globalThis.__ = (source) => source

// A face is only fetched once some text needs it, possibly after a screenshot was taken.
beforeAll(async () => {
  await Promise.all([...document.fonts].map((face) => face.load()))
})

beforeEach(() => commands.moveMouseAway())
