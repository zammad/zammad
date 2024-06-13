// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { storeToRefs } from 'pinia'
import { computed } from 'vue'

// eslint-disable-next-line import/no-restricted-paths
import { useThemeStore } from '#desktop/stores/theme.ts'

const neutralColors = [
  {
    name: __('black color scheme'),
    // default: {
    //   light: 950,
    //   dark: 50,
    // },
    values: [
      {
        value: '#000000',
        range: 950,
        label: __('Black'),
      },
      {
        value: '#4f4f4f',
        range: 700,
        label: __('Emperor'),
      },
      {
        value: '#6d6d6d',
        range: 500,
        label: __('Dove Gray'),
      },
      {
        value: '#b0b0b0',
        range: 300,
        label: __('Silver Chalice'),
      },
      {
        value: '#d1d1d1',
        range: 200,
        label: __('Alto'),
      },
      {
        value: '#ffffff',
        range: 50,
        label: __('White'),
      },
    ],
  },
]

const accentColors = [
  {
    name: 'red color scheme',
    // default: {
    //   light: 800,
    //   dark: 400,
    // },
    values: [
      {
        value: '#B00020',
        range: 800,
        label: __('Monza'),
      },
      // {
      //   value: '#db0028',
      //   range: 700,
      //   label: __('Red'),
      // },
      {
        value: '#ff002e',
        range: 600,
        label: __('Torch Red'),
      },
      {
        value: '#ff1f48',
        range: 500,
        label: __('Torch Red'),
      },
      {
        value: '#ff5473',
        range: 400,
        label: __('Wild Watermelon'),
      },
      {
        value: '#ff92a6',
        range: 300,
        label: __('Pink Salmon'),
      },
      // {
      //   value: '#ffbfcb',
      //   range: 200,
      //   label: __('Red'),
      // },
      {
        value: '#ffeff2',
        range: 50,
        label: __('Lavender blush'),
      },
    ],
  },
  // {
  //   name: 'orange',
  //   values: [],
  // },
  {
    name: 'yellow color scheme',
    default: {
      light: 400,
      dark: 100,
    },
    values: [
      {
        value: '#923f0e',
        range: 800,
        label: __('Korma'),
      },
      // {
      //   value: '#b45209',
      //   range: 700,
      //   label: __('Red'),
      // },
      {
        value: '#d97506',
        range: 600,
        label: __('Bamboo'),
      },
      {
        value: '#f59c0b',
        range: 500,
        label: __('Buttercup'),
      },
      {
        value: '#fbc02d',
        range: 400,
        label: __('Lightning Yellow'),
      },
      {
        value: '#fcd24d',
        range: 300,
        label: __('Bright Sun'),
      },
      // {
      //   value: '#fde58a',
      //   range: 200,
      //   label: __('Red'),
      // },
      {
        value: '#fef3c7',
        range: 100,
        label: __('Beeswax'),
      },
    ],
  },
  {
    name: 'green color scheme',
    default: {
      light: 600,
      dark: 300,
    },
    values: [
      {
        value: '#275429',
        range: 800,
        label: __('Everglade'),
      },
      // {
      //   value: '#2c692f',
      //   range: 700,
      //   label: __('Red'),
      // },
      {
        value: '#388e3c',
        range: 600,
        label: __('Apple'),
      },
      {
        value: '#45a249',
        range: 500,
        label: __('Apple'),
      },
      {
        value: '#6abe6e',
        range: 400,
        label: __('Fern'),
      },
      {
        value: '#9dd89f',
        range: 300,
        label: __('Moss Green'),
      },
      // {
      //   value: '#c8eac9',
      //   range: 200,
      //   label: __('Red'),
      // },
      {
        value: '#e3f5e3',
        range: 100,
        label: __('Peppermint'),
      },
    ],
  },
  {
    name: 'turkish color scheme',
    default: {
      light: 400,
      dark: 100,
    },
    values: [
      {
        value: '#215a69',
        range: 800,
        label: __('Cello'),
      },
      // {
      //   value: '#1e6e80',
      //   range: 700,
      //   label: __('Red'),
      // },
      {
        value: '#1d879d',
        range: 600,
        label: __('Eastern Blue'),
      },
      {
        value: '#1fa8bb',
        range: 500,
        label: __('Eastern Blue'),
      },
      {
        value: '#3bc5d5',
        range: 400,
        label: __('Scooter'),
      },
      {
        value: '#77dde7',
        range: 300,
        label: __('Sky Blue'),
      },
      // {
      //   value: '#b0edf1',
      //   range: 200,
      //   label: __('Red'),
      // },
      {
        value: '#d5f6f8',
        range: 100,
        label: __('White Ice'),
      },
    ],
  },
  {
    name: 'blue color scheme',
    default: {
      light: 800,
      dark: 400,
    },
    values: [
      {
        value: '#1c63b1',
        range: 800,
        label: __('Fun Blue'),
      },
      // {
      //   value: '#1976d2',
      //   range: 700,
      //   label: __('Red'),
      // },
      {
        value: '#2293ee',
        range: 600,
        label: __('Dodger Blue'),
      },
      {
        value: '#38aff9',
        range: 500,
        label: __('Dodger Blue'),
      },
      {
        value: '#5ecbfc',
        range: 400,
        label: __('Malibu'),
      },
      {
        value: '#91dfff',
        range: 300,
        label: __('Anakiwa'),
      },
      // {
      //   value: '#beebff',
      //   range: 200,
      //   label: __('Red'),
      // },
      {
        value: '#daf3ff',
        range: 100,
        label: __('Pattens Blue'),
      },
    ],
  },
  {
    name: 'purple color scheme',
    // default: {
    //   light: 800,
    //   dark: 300,
    // },
    values: [
      {
        value: '#741f89',
        range: 800,
        label: __('Seance'),
      },
      // {
      //   value: '#8e24aa',
      //   range: 700,
      //   label: __('Red'),
      // },
      {
        value: '#a62fca',
        range: 600,
        label: __('Purple Heart'),
      },
      {
        value: '#c14fe6',
        range: 500,
        label: __('Medium Purple'),
      },
      {
        value: '#d580f2',
        range: 400,
        label: __('Heliotrope'),
      },
      {
        value: '#e4aff8',
        range: 300,
        label: __('Perfume'),
      },
      // {
      //   value: '#efd2fc',
      //   range: 200,
      //   label: __('Red'),
      // },
      {
        value: '#f6e9fe',
        range: 100,
        label: __('Blue Chalk'),
      },
    ],
  },
]

const getDarkScheme = (scheme: typeof accentColors) =>
  scheme.flatMap((color) => {
    return {
      ...color,
      // eslint-disable-next-line @typescript-eslint/ban-ts-comment
      // @ts-expect-error
      values: color.values.toSorted(
        // es2023
        (colorA: { range: number }, colorB: { range: number }) =>
          colorA.range - colorB.range,
      ),
    }
  })

const getLightScheme = (scheme: typeof accentColors) => scheme

const lookupRootTheme = () => {
  const rootElement = document.documentElement
  return rootElement.getAttribute('data-theme')
}

export const useColorPallet = () => {
  const { currentTheme } = storeToRefs(useThemeStore())

  const accentColorPallet = computed(() => {
    if (currentTheme.value === 'dark') return getDarkScheme(accentColors)

    if (currentTheme.value === 'auto') {
      return lookupRootTheme() === 'dark'
        ? getDarkScheme(accentColors)
        : getLightScheme(accentColors)
    }

    return getLightScheme(accentColors)
  })

  const neutralColorPallet = computed(() => {
    if (currentTheme.value === 'dark') return getDarkScheme(neutralColors)

    if (currentTheme.value === 'auto') {
      return lookupRootTheme() === 'dark'
        ? getDarkScheme(neutralColors)
        : getLightScheme(neutralColors)
    }

    return getLightScheme(neutralColors)
  })

  return { accentColorPallet, neutralColorPallet }
}
