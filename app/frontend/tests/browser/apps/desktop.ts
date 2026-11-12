// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { initializeForm, initializeFormFields } from '#desktop/form/index.ts'
import { initializeDesktopVisuals } from '#desktop/initializer/desktopVisuals.ts'
import { initializeDesktopIcons } from '#desktop/initializer/initializeDesktopIcons.ts'
import { initializeGlobalComponentStyles } from '#desktop/initializer/initializeGlobalComponentStyles.ts'
import initializeGlobalDirectives from '#desktop/initializer/initializeGlobalDirectives.ts'
import { cacheInitializerModules } from '#desktop/server/apollo/index.ts'

import type { BrowserApp } from '../app.ts'

import '#desktop/styles/main.css'

export const desktopApp: BrowserApp = {
  name: 'desktop',
  plugins: [
    initializeGlobalComponentStyles,
    initializeGlobalDirectives,
    initializeDesktopIcons,
    initializeForm,
    initializeFormFields,
    initializeDesktopVisuals,
  ],
  cacheInitializerModules,
}
