// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { Story } from '@storybook/vue3'
import { FormKit } from '@formkit/vue'
import defaultArgTypes from '@stories/support/form/field/defaultArgTypes'
import type { FieldArgs } from '@stories/types/form'

export default {
  title: 'Form/Field/TreeSelect',
  component: FormKit,
  argTypes: {
    ...defaultArgTypes,
    options: {
      type: { name: 'array', required: true },
      description: 'List of selection options',
      table: {
        expanded: true,
        type: {
          summary: 'TreeSelectOption[]',
          detail: `{
  value: string | number
  label: string
  labelPlaceholder?: string[]
  disabled?: boolean
  status?: TicketState
  icon?: string
  children?: TreeSelectOption[]
}`,
        },
      },
    },
    autoselect: {
      description:
        'Automatically selects last option when and only when option list length equals one',
    },
    clearable: {
      description: 'Allows clearing of selected values',
    },
    noFiltering: {
      description: 'Disables filtering of selection options',
    },
    multiple: {
      description: 'Allows multi selection',
    },
    noOptionsLabelTranslation: {
      description: 'Skips translation of option labels',
    },
    sorting: {
      type: { name: 'string', required: false },
      description: 'Sorts options by property',
      table: {
        type: {
          summary: "'label' | 'value'",
        },
      },
      options: [undefined, 'label', 'value'],
      control: {
        type: 'select',
      },
    },
  },
}

const Template: Story<FieldArgs> = (args: FieldArgs) => ({
  components: { FormKit },
  setup() {
    return { args }
  },
  template: '<FormKit type="treeselect" v-bind="args"/>',
})

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

export const Default = Template.bind({})
Default.args = {
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
}

export const DefaultValue = Template.bind({})
DefaultValue.args = {
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
}

export const ClearableValue = Template.bind({})
ClearableValue.args = {
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
}

export const NoOptionFiltering = Template.bind({})
NoOptionFiltering.args = {
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
}

export const DisabledState = Template.bind({})
DisabledState.args = {
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
}

export const MultipleSelection = Template.bind({})
MultipleSelection.args = {
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
}

export const OptionSorting = Template.bind({})
OptionSorting.args = {
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
}

export const OptionTranslation = Template.bind({})
OptionTranslation.args = {
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
}

export const OptionAutoselect = Template.bind({})
OptionAutoselect.args = {
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
}

export const OptionDisabled = Template.bind({})
OptionDisabled.args = {
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
}

export const OptionStatus = Template.bind({})
OptionStatus.args = {
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
}

export const OptionIcon = Template.bind({})
OptionIcon.args = {
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
}
