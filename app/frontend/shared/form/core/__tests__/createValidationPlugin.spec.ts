// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import createValidationPlugin, {
  getValidationRuleMessages,
} from '@shared/form/core/createValidationPlugin'

describe('createValidationPlugin', () => {
  it('check that validation plugin will be returned', () => {
    const validationPlugin = createValidationPlugin()

    expect(typeof validationPlugin).toEqual('function')
  })
})

describe('getValidationRuleMessages', () => {
  // TODO: At the moment the rule messages are empty, because no custom rules exists, needs to be improved,
  // when we have our first custom rules.
  it('get validation messages from custom rules', () => {
    const validationRuleMessages = getValidationRuleMessages()

    expect(validationRuleMessages).toEqual({})
  })
})
