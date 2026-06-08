// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { toRef } from 'vue'

import { getTailwindStyleValue } from '#shared/utils/tailwind.ts'

import { useThemeStore } from '#desktop/stores/theme.ts'

// eslint-disable-next-line zammad/zammad-detect-translatable-string
const CHART_FONT_FAMILY = 'Fira Sans, Helvetica Neue, Helvetica, Arial, sans-serif'

export const useChartStyles = () => {
  const isDarkMode = toRef(useThemeStore(), 'isDarkMode')

  const colorMap = {
    'neutral-50': getTailwindStyleValue('--color-neutral-50'),
    'neutral-500': getTailwindStyleValue('--color-neutral-500'),
    'neutral-700': getTailwindStyleValue('--color-neutral-700'),
    'neutral-800': getTailwindStyleValue('--color-neutral-800'),
    'stone-200': getTailwindStyleValue('--color-stone-200'),
    'stone-400': getTailwindStyleValue('--color-stone-400'),
    'neutral-100': getTailwindStyleValue('--color-neutral-100'),
    'neutral-400': getTailwindStyleValue('--color-neutral-400'),
    'gray-100': getTailwindStyleValue('--color-gray-100'),
    'gray-200': getTailwindStyleValue('--color-gray-200'),
    'green-400': getTailwindStyleValue('--color-green-400'),
    'gray-500': getTailwindStyleValue('--color-gray-500'),
    'gray-700': getTailwindStyleValue('--color-gray-700'),
    'gray-900': getTailwindStyleValue('--color-gray-900'),
    white: getTailwindStyleValue('--color-white'),
    black: getTailwindStyleValue('--color-black'),
  }

  return {
    fontFamily: CHART_FONT_FAMILY,
    colorMap,
    isDarkMode,
  }
}
