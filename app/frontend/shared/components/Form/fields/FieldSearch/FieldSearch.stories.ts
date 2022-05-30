// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { FormKit } from '@formkit/vue'
import defaultArgTypes from '@stories/support/form/field/defaultArgTypes'
import createTemplate from '@stories/support/createTemplate'

export default {
  title: 'Form/Field/Inputs/Search',
  component: FormKit,
  argTypes: {
    ...defaultArgTypes,
    placeholder: {
      name: 'placeholder',
      type: { name: 'text', required: false },
      desciption: '',
      table: {
        type: { summary: 'text' },
      },
      control: {
        type: 'text',
      },
    },
  },
}

const Template = createTemplate(FormKit)

export const Default = Template.create({
  type: 'search',
  name: 'search',
})
