<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

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
    autoselect: false,
    clearable: false,
    multiple: false,
    noOptionsLabelTranslation: false,
    size: null,
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
    autoselect: false,
    clearable: false,
    multiple: false,
    noOptionsLabelTranslation: false,
    size: null,
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
    autoselect: false,
    clearable: true,
    multiple: false,
    noOptionsLabelTranslation: false,
    size: null,
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
    autoselect: false,
    clearable: false,
    multiple: false,
    noOptionsLabelTranslation: false,
    size: null,
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
    autoselect: false,
    clearable: false,
    multiple: true,
    noOptionsLabelTranslation: false,
    size: null,
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
    autoselect: false,
    clearable: false,
    multiple: false,
    noOptionsLabelTranslation: false,
    size: null,
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
    autoselect: false,
    clearable: false,
    multiple: false,
    noOptionsLabelTranslation: false,
    size: null,
    sorting: null,
    label: 'Option Translation',
    name: 'select_translation',
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
    autoselect: false,
    clearable: false,
    multiple: false,
    noOptionsLabelTranslation: false,
    size: null,
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
    autoselect: false,
    clearable: false,
    multiple: false,
    noOptionsLabelTranslation: false,
    size: null,
    sorting: null,
    label: 'Option Status',
    name: 'select_status',
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
    multiple: false,
    noOptionsLabelTranslation: false,
    size: null,
    sorting: null,
    label: 'Option Icon',
    name: 'select_icon',
  },
  {
    options: [
      {
        value: 'note',
        label: 'Note',
      },
      {
        value: 'phone',
        label: 'Phone',
      },
      {
        value: 'email',
        label: 'Email',
      },
    ],
    autoselect: false,
    clearable: false,
    multiple: false,
    noOptionsLabelTranslation: false,
    size: 'small',
    sorting: null,
    name: 'select_small',
    label: 'Small Size',
    value: 'note',
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
