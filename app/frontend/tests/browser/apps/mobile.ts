// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { initializeForm, initializeFormFields } from '#mobile/form/index.ts'
import { initializeGlobalComponentStyles } from '#mobile/initializer/initializeGlobalComponentStyles.ts'
import initializeGlobalDirectives from '#mobile/initializer/initializeGlobalDirectives.ts'
import { initializeMobileIcons } from '#mobile/initializer/initializeMobileIcons.ts'
import { initializeMobileVisuals } from '#mobile/initializer/mobileVisuals.ts'
import { cacheInitializerModules } from '#mobile/server/apollo/index.ts'

import type { BrowserApp } from '../app.ts'

import '#mobile/styles/main.css'

export const mobileApp: BrowserApp = {
  name: 'mobile',
  plugins: [
    initializeGlobalComponentStyles,
    initializeGlobalDirectives,
    initializeMobileIcons,
    initializeForm,
    initializeFormFields,
    initializeMobileVisuals,
  ],
  cacheInitializerModules,
}
