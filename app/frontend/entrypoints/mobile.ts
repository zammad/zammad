// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import mountApp from '#mobile/main.ts'
import { registerPWAHooks } from '#shared/utils/pwa.ts'

registerPWAHooks()
mountApp()
