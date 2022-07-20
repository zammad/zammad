// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import type { Story } from '@storybook/vue3'
import { FormKit } from '@formkit/vue'
import defaultArgTypes from '@stories/support/form/field/defaultArgTypes'
import type { FieldArgs } from '@stories/types/form'

export default {
  title: 'Form/Field/Select',
  component: FormKit,
  argTypes: {
    ...defaultArgTypes,
    options: {
      type: { name: 'array', required: true },
      description: 'List of selection options',
      table: {
        expanded: true,
        type: {
          summary: 'SelectOption[]',
          detail: `{
  value: string | number
  label: string
  labelPlaceholder?: string[]
  disabled?: boolean
  status?: TicketState
  icon?: string
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
    multiple: {
      description: 'Allows multi selection',
    },
    noOptionsLabelTranslation: {
      description: 'Skips translation of option labels',
    },
    size: {
      type: { name: 'string', required: false },
      description: 'Renders field in selected size',
      table: {
        type: {
          summary: "'small' | 'medium'",
        },
      },
      options: [undefined, 'small', 'medium'],
      control: {
        type: 'select',
      },
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
  template: '<FormKit type="select" v-bind="args"/>',
})

export const Default = Template.bind({})
Default.args = {
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
}

export const DefaultValue = Template.bind({})
DefaultValue.args = {
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
}

export const ClearableValue = Template.bind({})
ClearableValue.args = {
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
}

export const DisabledState = Template.bind({})
DisabledState.args = {
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
}

export const MultipleSelection = Template.bind({})
MultipleSelection.args = {
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
}

export const OptionSorting = Template.bind({})
OptionSorting.args = {
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
}

export const OptionTranslation = Template.bind({})
OptionTranslation.args = {
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
  multiple: false,
  noOptionsLabelTranslation: false,
  size: null,
  sorting: null,
  label: 'Option Status',
  name: 'select_status',
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
  multiple: false,
  noOptionsLabelTranslation: false,
  size: null,
  sorting: null,
  label: 'Option Icon',
  name: 'select_icon',
}

export const SmallSize = Template.bind({})
SmallSize.args = {
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
  value: 'note',
}
