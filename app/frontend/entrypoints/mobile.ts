// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import mountApp from '@mobile/main'
import { registerSW } from '@shared/sw/register'

mountApp()
registerSW({
  path: '/mobile/sw.js',
  scope: '/mobile/',
})
