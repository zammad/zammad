<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { FormKit } from '@formkit/vue'

const options = [
  {
    options: [
      {
        value: 0,
        label: 'Item A',
      },
      {
        value: 1,
        label: 'Item B',
      },
      {
        value: 2,
        label: 'Item C',
      },
    ],
    clearable: false,
    multiple: false,
    noOptionsLabelTranslation: false,
    sorting: null,
    label: 'Select',
    name: 'select',
  },
  {
    options: [
      {
        value: 0,
        label: 'Item A',
      },
      {
        value: 1,
        label: 'Item B',
      },
      {
        value: 2,
        label: 'Item C',
      },
    ],
    clearable: false,
    multiple: false,
    noOptionsLabelTranslation: false,
    sorting: null,
    label: 'Default Value',
    name: 'select_default_value',
    value: 0,
  },
  {
    options: [
      {
        value: 0,
        label: 'Item A',
      },
      {
        value: 1,
        label: 'Item B',
      },
      {
        value: 2,
        label: 'Item C',
      },
    ],
    clearable: true,
    multiple: false,
    noOptionsLabelTranslation: false,
    sorting: null,
    label: 'Clearable Value',
    name: 'select_clearable',
    value: 1,
  },
  {
    options: [
      {
        value: 0,
        label: 'Item A',
      },
      {
        value: 1,
        label: 'Item B',
      },
      {
        value: 2,
        label: 'Item C',
      },
    ],
    clearable: false,
    multiple: false,
    noOptionsLabelTranslation: false,
    sorting: null,
    label: 'Disabled State',
    name: 'select_disabled',
    value: 2,
    disabled: true,
  },
  {
    options: [
      {
        value: 0,
        label: 'Item A',
      },
      {
        value: 1,
        label: 'Item B',
      },
      {
        value: 2,
        label: 'Item C',
      },
    ],
    clearable: false,
    multiple: true,
    noOptionsLabelTranslation: false,
    sorting: null,
    label: 'Multiple Selection',
    name: 'select_multiple',
    value: [0, 2],
  },
  {
    options: [
      {
        value: 1,
        label: 'Item B',
      },
      {
        value: 2,
        label: 'Item C',
      },
      {
        value: 0,
        label: 'Item A',
      },
    ],
    clearable: false,
    multiple: false,
    noOptionsLabelTranslation: false,
    sorting: 'label',
    label: 'Option Sorting',
    name: 'select_sorting',
  },
  {
    options: [
      {
        value: 0,
        label: 'Item A (%s)',
        labelPlaceholder: ['1st'],
      },
      {
        value: 1,
        label: 'Item B (%s)',
        labelPlaceholder: ['2nd'],
      },
      {
        value: 2,
        label: 'Item C (%s)',
        labelPlaceholder: ['3rd'],
      },
    ],
    clearable: false,
    multiple: false,
    noOptionsLabelTranslation: false,
    sorting: null,
    label: 'Option Translation',
    name: 'select_translation',
  },
  {
    options: [
      {
        value: 0,
        label: 'Item A',
      },
      {
        value: 1,
        label: 'Item B',
        disabled: true,
      },
      {
        value: 2,
        label: 'Item C',
      },
    ],
    clearable: false,
    multiple: false,
    noOptionsLabelTranslation: false,
    sorting: null,
    label: 'Option Disabled',
    name: 'select_disabled',
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
    clearable: false,
    multiple: false,
    noOptionsLabelTranslation: false,
    sorting: null,
    label: 'Option Status',
    name: 'select_status',
  },
  {
    options: [
      {
        value: 1,
        label: 'GitLab',
        icon: 'mobile-gitlab',
      },
      {
        value: 2,
        label: 'GitHub',
        icon: 'mobile-github',
      },
    ],
    clearable: false,
    multiple: false,
    noOptionsLabelTranslation: false,
    sorting: null,
    label: 'Option Icon',
    name: 'select_icon',
  },
]
</script>

<template>
  <Story title="FieldSelect">
    <Variant
      v-for="(option, idx) in options"
      :key="idx"
      :title="option.label || option.name"
    >
      <FormKit type="select" v-bind="option" />
    </Variant>
  </Story>
</template>
