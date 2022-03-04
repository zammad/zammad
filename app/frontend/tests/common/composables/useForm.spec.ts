// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import Form from '@common/components/form/Form.vue'
import useForm from '@common/composables/useForm'
import { getWrapper } from '@tests/support/components'

const wrapperParameters = {
  form: true,
  attachTo: document.body,
}

// Initialize a form component.
getWrapper(Form, {
  ...wrapperParameters,
  props: {
    id: 'test-form',
    schema: [
      {
        type: 'text',
        name: 'title',
        label: 'Title',
      },
      {
        type: 'textarea',
        name: 'text',
        label: 'Text',
        value: 'Some text',
      },
    ],
  },
})

describe('useForm', () => {
  it('not existing form node', () => {
    const { formNode } = useForm('wrong-form-id')
    expect(formNode).toBeUndefined()
  })

  it('existing form node', () => {
    const { formNode } = useForm('test-form')

    expect(formNode).toBeDefined()
    expect(formNode?.value).toStrictEqual({
      title: undefined,
      text: 'Some text',
    })
  })
})
