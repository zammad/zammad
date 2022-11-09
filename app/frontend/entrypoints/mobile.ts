// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import mountApp from '@mobile/main'
import { registerPWAHooks } from '@shared/utils/pwa'

registerPWAHooks()
mountApp()
