// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

const argTypes = {
  name: {
    name: 'name',
    type: { name: 'string', required: false },
    description: '',
    table: {
      type: { summary: 'string' },
    },
    control: {
      type: 'text',
    },
  },
  label: {
    name: 'label',
    type: { name: 'string', required: false },
    description: '',
    table: {
      type: { summary: 'string' },
    },
    control: {
      type: 'text',
    },
  },
  labelPlaceholder: {
    name: 'labelPlaceholder',
    type: { name: 'array', required: false },
    description: '',
    table: {
      type: { summary: 'string' },
    },
    control: {
      type: 'object',
    },
  },
  value: {
    name: 'value',
    type: { name: 'string', required: false },
    description: '',
    table: {
      type: { summary: 'string' },
    },
    control: {
      type: 'text',
    },
  },
  id: {
    name: 'id',
    type: { name: 'string', required: false },
    description: '',
    table: {
      type: { summary: 'string' },
    },
    control: {
      type: 'text',
    },
  },
  help: {
    name: 'help',
    type: { name: 'string', required: false },
    description: '',
    table: {
      type: { summary: 'string' },
    },
    control: {
      type: 'text',
    },
  },
  disabled: {
    name: 'disabled',
    type: { name: 'boolean', required: false },
    desciption: '',
    table: {
      type: { summary: 'false' },
    },
    control: {
      type: 'boolean',
    },
  },
  config: {
    name: 'config',
    type: { name: 'object', required: false },
    description:
      'Configuration options to provide to the input’s node and any descendent node of this input.',
    table: {
      type: { summary: 'object' },
      defaultValue: {
        summary: '{}',
      },
    },
    control: {
      type: 'object',
    },
  },
  classes: {
    name: 'classes',
    type: { name: 'object', required: false },
    description: 'https://formkit.com/essentials/styling#custom-classes',
    table: {
      type: { summary: 'object | function' },
      defaultValue: {
        summary: '{}',
      },
    },
    control: {
      type: 'object',
    },
  },
  delay: {
    name: 'delay',
    type: { name: 'number', required: false },
    desciption:
      'Number of milliseconds to debounce an input’s value before the commit hook is dispatched.',
    table: {
      type: { summary: 'number' },
      defaultValue: {
        summary: '20',
      },
    },
    control: {
      type: 'number',
    },
  },
  errors: {
    name: 'errors',
    type: { name: 'array', required: false },
    description: 'Array of strings to show as error messages on this field.',
    table: {
      type: { summary: 'string[]' },
      defaultValue: {
        summary: '[]',
      },
    },
    control: {
      type: 'object',
      value: [],
    },
  },
  plugins: {
    name: 'plugins',
    type: { name: 'array', required: false },
    description: 'Array of plugins to add special field behaviour.',
    table: {
      type: { summary: 'function[]' },
      defaultValue: {
        summary: '[]',
      },
    },
    control: false,
  },
  sectionsSchema: {
    name: 'sectionsSchema',
    type: { name: 'object', required: false },
    description:
      'An object of section keys and schema partial values, where each schema partial is applied to the [respective section](https://formkit.com/inputs/textarea#section-keys).',
    table: {
      type: { summary: 'object' },
      defaultValue: {
        summary: '{}',
      },
    },
    control: {
      type: 'object',
    },
  },
  validation: {
    name: 'validation',
    type: { name: 'string', required: false },
    description:
      'The [validation rules](https://formkit.com/essentials/validation) to be applied to the input.',
    table: {
      type: { summary: 'string | array' },
    },
    control: {
      type: 'text',
    },
  },
  validationMessages: {
    name: 'validationMessages',
    type: { name: 'object', required: false },
    description:
      'To override a validation message on a single input with object of rule names and a corresponding message.',
    table: {
      type: { summary: 'object' },
      defaultValue: {
        summary: '{}',
      },
    },
    control: {
      type: 'object',
    },
  },
  validationRules: {
    name: 'validationRules',
    type: { name: 'object', required: false },
    description:
      'Additional custom validation rules to make available to the validation prop.',
    table: {
      type: { summary: 'object' },
      defaultValue: {
        summary: '{}',
      },
    },
    control: {
      type: 'object',
    },
  },
  validationVisibility: {
    name: 'validationVisibility',
    type: { name: 'string', required: false },
    description:
      'Determines when to show an input’s failing validation rules. Valid values are blur, dirty, and live.',
    table: {
      type: { summary: 'string' },
      defaultValue: {
        summary: 'blur',
      },
    },
    options: ['blur', 'dirty', 'live'],
    control: {
      type: 'select',
    },
  },
}

export default argTypes
