// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { renderComponent } from '#tests/support/components/index.ts'

import CommonHelpText from '#desktop/components/CommonPageHelp/CommonHelpText.vue'

describe('CommonHelpText', () => {
  it('supports single Paragraph', () => {
    const wrapper = renderComponent(CommonHelpText, {
      props: {
        helpText: 'Hello Test World!',
      },
    })
    expect(wrapper.getByText('Hello Test World!')).toBeInTheDocument()
  })
  it('supports multiple Paragraph', () => {
    const wrapper = renderComponent(CommonHelpText, {
      props: {
        helpText: ['Hello Test World!', 'Hello Foo World!'],
      },
    })

    expect(wrapper.getByText('Hello Test World!')).toBeInTheDocument()
    expect(wrapper.getByText('Hello Foo World!')).toBeInTheDocument()
  })
})
