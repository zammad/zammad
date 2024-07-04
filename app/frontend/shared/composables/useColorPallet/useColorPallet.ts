// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

/* eslint-disable zammad/zammad-detect-translatable-string */

import { storeToRefs } from 'pinia'
import { computed } from 'vue'

import getUuid from '#shared/utils/getUuid.ts'

// eslint-disable-next-line import/no-restricted-paths
import { useThemeStore } from '#desktop/stores/theme.ts'

const neutralColors = [
  {
    name: 'black color scheme',
    // default: {
    //   light: 950,
    //   dark: 50,
    // },
    values: [
      {
        value: '#000000',
        range: 950,
        label: 'Black',
      },
      {
        value: '#4f4f4f',
        range: 700,
        label: 'Emperor',
      },
      {
        value: '#6d6d6d',
        range: 500,
        label: 'Dove Gray',
      },
      {
        value: '#b0b0b0',
        range: 300,
        label: 'Silver Chalice',
      },
      {
        value: '#d1d1d1',
        range: 200,
        label: 'Alto',
      },
      {
        value: '#ffffff',
        range: 50,
        label: 'White',
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
        label: 'Monza',
      },
      // {
      //   value: '#db0028',
      //   range: 700,
      //   label: 'Red',
      // },
      {
        value: '#ff002e',
        range: 600,
        label: 'Torch Red',
      },
      {
        value: '#ff1f48',
        range: 500,
        label: 'Torch Red',
      },
      {
        value: '#ff5473',
        range: 400,
        label: 'Wild Watermelon',
      },
      {
        value: '#ff92a6',
        range: 300,
        label: 'Pink Salmon',
      },
      // {
      //   value: '#ffbfcb',
      //   range: 200,
      //   label: 'Red',
      // },
      {
        value: '#ffeff2',
        range: 50,
        label: 'Lavender blush',
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
        label: 'Korma',
      },
      // {
      //   value: '#b45209',
      //   range: 700,
      //   label: 'Red',
      // },
      {
        value: '#d97506',
        range: 600,
        label: 'Bamboo',
      },
      {
        value: '#f59c0b',
        range: 500,
        label: 'Buttercup',
      },
      {
        value: '#fbc02d',
        range: 400,
        label: 'Lightning Yellow',
      },
      {
        value: '#fcd24d',
        range: 300,
        label: 'Bright Sun',
      },
      // {
      //   value: '#fde58a',
      //   range: 200,
      //   label: 'Red',
      // },
      {
        value: '#fef3c7',
        range: 100,
        label: 'Beeswax',
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
        label: 'Everglade',
      },
      // {
      //   value: '#2c692f',
      //   range: 700,
      //   label: 'Red',
      // },
      {
        value: '#388e3c',
        range: 600,
        label: 'Apple',
      },
      {
        value: '#45a249',
        range: 500,
        label: 'Apple',
      },
      {
        value: '#6abe6e',
        range: 400,
        label: 'Fern',
      },
      {
        value: '#9dd89f',
        range: 300,
        label: 'Moss Green',
      },
      // {
      //   value: '#c8eac9',
      //   range: 200,
      //   label: 'Red',
      // },
      {
        value: '#e3f5e3',
        range: 100,
        label: 'Peppermint',
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
        label: 'Cello',
      },
      // {
      //   value: '#1e6e80',
      //   range: 700,
      //   label: 'Red',
      // },
      {
        value: '#1d879d',
        range: 600,
        label: 'Eastern Blue',
      },
      {
        value: '#1fa8bb',
        range: 500,
        label: 'Eastern Blue',
      },
      {
        value: '#3bc5d5',
        range: 400,
        label: 'Scooter',
      },
      {
        value: '#77dde7',
        range: 300,
        label: 'Sky Blue',
      },
      // {
      //   value: '#b0edf1',
      //   range: 200,
      //   label: 'Red',
      // },
      {
        value: '#d5f6f8',
        range: 100,
        label: 'White Ice',
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
        label: 'Fun Blue',
      },
      // {
      //   value: '#1976d2',
      //   range: 700,
      //   label: 'Red',
      // },
      {
        value: '#2293ee',
        range: 600,
        label: 'Dodger Blue',
      },
      {
        value: '#38aff9',
        range: 500,
        label: 'Dodger Blue',
      },
      {
        value: '#5ecbfc',
        range: 400,
        label: 'Malibu',
      },
      {
        value: '#91dfff',
        range: 300,
        label: 'Anakiwa',
      },
      // {
      //   value: '#beebff',
      //   range: 200,
      //   label: 'Red',
      // },
      {
        value: '#daf3ff',
        range: 100,
        label: 'Pattens Blue',
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
        label: 'Seance',
      },
      // {
      //   value: '#8e24aa',
      //   range: 700,
      //   label: 'Red',
      // },
      {
        value: '#a62fca',
        range: 600,
        label: 'Purple Heart',
      },
      {
        value: '#c14fe6',
        range: 500,
        label: 'Medium Purple',
      },
      {
        value: '#d580f2',
        range: 400,
        label: 'Heliotrope',
      },
      {
        value: '#e4aff8',
        range: 300,
        label: 'Perfume',
      },
      // {
      //   value: '#efd2fc',
      //   range: 200,
      //   label: 'Red',
      // },
      {
        value: '#f6e9fe',
        range: 100,
        label: 'Blue Chalk',
      },
    ],
  },
]

const highlightColors = [
  {
    value: { light: '#f7e7b2', dark: 'rgba(247,231,178,0.3)' },
    name: 'Dairy Cream',
    label: 'Yellow',
    id: getUuid(),
  },
  {
    value: {
      light: '#bce7b6',
      dark: 'rgba(188,231,182,0.3)',
    },
    name: 'Celadon',
    label: 'Green',
    id: getUuid(),
  },
  {
    value: {
      light: '#b3ddf9',
      dark: 'rgba(179,221,249,0.3)',
    },
    name: 'Sail',
    label: 'Blue',
    id: getUuid(),
  },
  {
    value: {
      light: '#fea9c5',
      dark: 'rgba(254,169,197,0.3)',
    },
    name: 'Carnation Pink',
    label: 'Pink',
    id: getUuid(),
  },
  {
    value: {
      light: '#eac5ee',
      dark: 'rgba(234,197,238,0.3)',
    },
    name: 'French Lilac',
    label: 'Purple',
    id: getUuid(),
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

  return { accentColorPallet, neutralColorPallet, highlightColors }
}
