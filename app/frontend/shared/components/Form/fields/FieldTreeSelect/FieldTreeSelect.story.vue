<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { FormKit } from '@formkit/vue'

const testOptions = [
  {
    value: 0,
    label: 'Item A',
    children: [
      {
        value: 1,
        label: 'Item 1',
        children: [
          {
            value: 2,
            label: 'Item I',
          },
          {
            value: 3,
            label: 'Item II',
          },
          {
            value: 4,
            label: 'Item III',
          },
        ],
      },
      {
        value: 5,
        label: 'Item 2',
        children: [
          {
            value: 6,
            label: 'Item IV',
          },
        ],
      },
      {
        value: 7,
        label: 'Item 3',
      },
    ],
  },
  {
    value: 8,
    label: 'Item B',
  },
  {
    value: 9,
    label: 'Ítem C',
  },
]

const options = [
  {
    options: testOptions,
    autoselect: false,
    clearable: false,
    noFiltering: false,
    multiple: false,
    noOptionsLabelTranslation: false,
    size: null,
    sorting: null,
    label: 'Tree Select',
    name: 'treeselect',
  },
  {
    options: testOptions,
    autoselect: false,
    clearable: false,
    noFiltering: false,
    multiple: false,
    noOptionsLabelTranslation: false,
    size: null,
    sorting: null,
    label: 'Default Value',
    name: 'treeselect_default_value',
    value: 0,
  },
  {
    options: testOptions,
    autoselect: false,
    clearable: true,
    noFiltering: false,
    multiple: false,
    noOptionsLabelTranslation: false,
    size: null,
    sorting: null,
    label: 'Clearable Value',
    name: 'treeselect_clearable',
    value: 1,
  },
  {
    options: testOptions,
    autoselect: false,
    clearable: false,
    noFiltering: true,
    multiple: false,
    noOptionsLabelTranslation: false,
    size: null,
    sorting: null,
    label: 'No Option Filtering',
    name: 'treeselect_no_filtering',
  },
  {
    options: testOptions,
    autoselect: false,
    clearable: false,
    noFiltering: false,
    multiple: false,
    noOptionsLabelTranslation: false,
    size: null,
    sorting: null,
    label: 'Disabled State',
    name: 'treeselect_disabled',
    value: 2,
    disabled: true,
  },
  {
    options: testOptions,
    autoselect: false,
    clearable: false,
    noFiltering: false,
    multiple: true,
    noOptionsLabelTranslation: false,
    size: null,
    sorting: null,
    label: 'Multiple Selection',
    name: 'treeselect_multiple',
    value: [0, 2],
  },
  {
    options: [
      {
        value: 8,
        label: 'Item B',
      },
      {
        value: 9,
        label: 'Ítem C',
      },
      {
        value: 0,
        label: 'Item A',
        children: [
          {
            value: 5,
            label: 'Item 2',
            children: [
              {
                value: 6,
                label: 'Item IV',
              },
            ],
          },
          {
            value: 7,
            label: 'Item 3',
          },
          {
            value: 1,
            label: 'Item 1',
            children: [
              {
                value: 3,
                label: 'Item II',
              },
              {
                value: 4,
                label: 'Item III',
              },
              {
                value: 2,
                label: 'Item I',
              },
            ],
          },
        ],
      },
    ],
    autoselect: false,
    clearable: false,
    noFiltering: false,
    multiple: false,
    noOptionsLabelTranslation: false,
    size: null,
    sorting: 'label',
    label: 'Option Sorting',
    name: 'treeselect_sorting',
  },
  {
    options: [
      {
        value: 0,
        label: 'Item A (%s)',
        labelPlaceholder: ['1st'],
        children: [
          {
            value: 1,
            label: 'Item 1 (%s)',
            labelPlaceholder: ['2nd'],
            children: [
              {
                value: 2,
                label: 'Item I (%s)',
                labelPlaceholder: ['3rd'],
              },
              {
                value: 3,
                label: 'Item II (%s)',
                labelPlaceholder: ['4th'],
              },
              {
                value: 4,
                label: 'Item III (%s)',
                labelPlaceholder: ['5th'],
              },
            ],
          },
          {
            value: 5,
            label: 'Item 2 (%s)',
            labelPlaceholder: ['6th'],
            children: [
              {
                value: 6,
                label: 'Item IV (%s)',
                labelPlaceholder: ['7th'],
              },
            ],
          },
          {
            value: 7,
            label: 'Item 3 (%s)',
            labelPlaceholder: ['8th'],
          },
        ],
      },
      {
        value: 8,
        label: 'Item B (%s)',
        labelPlaceholder: ['9th'],
      },
      {
        value: 9,
        label: 'Ítem C (%s)',
        labelPlaceholder: ['10th'],
      },
    ],
    autoselect: false,
    clearable: false,
    noFiltering: false,
    multiple: false,
    noOptionsLabelTranslation: false,
    size: null,
    sorting: null,
    label: 'Option Translation',
    name: 'treeselect_translation',
  },
  {
    options: [
      {
        value: 1,
        label: 'The One',
      },
    ],
    autoselect: true,
    clearable: false,
    noFiltering: false,
    multiple: false,
    noOptionsLabelTranslation: false,
    size: null,
    sorting: null,
    label: 'Option Autoselect',
    name: 'select_autoselect',
  },
  {
    options: [
      {
        value: 0,
        label: 'Item A',
        children: [
          {
            value: 1,
            label: 'Item 1',
            children: [
              {
                value: 2,
                label: 'Item I',
              },
              {
                value: 3,
                label: 'Item II',
                disabled: true,
              },
              {
                value: 4,
                label: 'Item III',
              },
            ],
          },
          {
            value: 5,
            label: 'Item 2',
            disabled: true,
            children: [
              {
                value: 6,
                label: 'Item IV',
              },
            ],
          },
          {
            value: 7,
            label: 'Item 3',
          },
        ],
      },
      {
        value: 8,
        label: 'Item B',
        disabled: true,
      },
      {
        value: 9,
        label: 'Ítem C',
      },
    ],
    autoselect: false,
    clearable: false,
    noFiltering: false,
    multiple: false,
    noOptionsLabelTranslation: false,
    size: null,
    sorting: null,
    label: 'Option Disabled',
    name: 'treeselect_disabled',
  },
  {
    options: [
      {
        value: 'open',
        label: 'Open',
        status: 'open',
      },
      {
        value: 'closed',
        label: 'Closed',
        status: 'closed',
      },
      {
        value: 'waiting-for-reminder',
        label: 'Waiting for closure',
        status: 'waiting-for-reminder',
      },
      {
        value: 'waiting-for-closure',
        label: 'Waiting for reminder',
        status: 'waiting-for-closure',
      },
      {
        value: 'escalated',
        label: 'Escalated',
        status: 'escalated',
      },
    ],
    autoselect: false,
    clearable: false,
    noFiltering: false,
    multiple: false,
    noOptionsLabelTranslation: false,
    size: null,
    sorting: null,
    label: 'Option Status',
    name: 'treeselect_status',
  },
  {
    options: [
      {
        value: 1,
        label: 'GitLab',
        icon: 'gitlab-logo',
      },
      {
        value: 2,
        label: 'GitHub',
        icon: 'github-logo',
      },
    ],
    autoselect: false,
    clearable: false,
    noFiltering: false,
    multiple: false,
    noOptionsLabelTranslation: false,
    size: null,
    sorting: null,
    label: 'Option Icon',
    name: 'treeselect_icon',
  },
]
</script>

<template>
  <Story>
    <Variant
      v-for="(option, idx) in options"
      :key="idx"
      :title="option.label || option.name"
    >
      <FormKit type="treeselect" v-bind="option" />
    </Variant>
  </Story>
</template>
