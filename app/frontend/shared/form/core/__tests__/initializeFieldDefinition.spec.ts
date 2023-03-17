// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import {
  text as inputTextDefinition,
  select as selectDefinition,
} from '@formkit/inputs'
import initializeFieldDefinition from '@shared/form/core/initializeFieldDefinition'
import { cloneDeep } from 'lodash-es'
import translateWrapperProps from '@shared/form/features/translateWrapperProps'
import addBlurEvent from '@shared/form/features/addBlurEvent'
import hideField from '@shared/form/features/hideField'

describe('initializeFieldDefinition', () => {
  it('check for added default props without already existing props', () => {
    const definition = cloneDeep(inputTextDefinition)
    initializeFieldDefinition(definition)

    expect(definition.props).toEqual([
      'formId',
      'labelSrOnly',
      'labelPlaceholder',
      'internal',
    ])
  })

  it('check for added default props with existing props', () => {
    const definition = cloneDeep(selectDefinition)
    initializeFieldDefinition(definition)

    expect(definition.props).toEqual([
      ...(selectDefinition.props || []),
      'formId',
      'labelSrOnly',
      'labelPlaceholder',
      'internal',
    ])
  })

  it('check for added default features without already existing features', () => {
    const definition = cloneDeep(inputTextDefinition)
    initializeFieldDefinition(definition)

    expect(definition.features).toEqual([
      translateWrapperProps,
      hideField,
      addBlurEvent,
    ])
  })

  it('check for added default features with existing features', () => {
    const definition = cloneDeep(selectDefinition)
    initializeFieldDefinition(definition)

    expect(definition.features).toEqual([
      translateWrapperProps,
      hideField,
      addBlurEvent,
      ...(selectDefinition.features || []),
    ])
  })

  it('do not add default props', () => {
    const definition = cloneDeep(inputTextDefinition)
    initializeFieldDefinition(definition, {}, { addDefaultProps: false })

    expect(definition.props).toEqual([])
  })

  it('do not add default features', () => {
    const definition = cloneDeep(inputTextDefinition)
    initializeFieldDefinition(
      definition,
      {},
      { addDefaultProps: true, addDefaultFeatures: false },
    )

    expect(definition.features).toEqual([])
  })

  it('add additional props and features', () => {
    const featureExample = vi.fn()

    const definition = cloneDeep(inputTextDefinition)
    initializeFieldDefinition(definition, {
      props: ['example'],
      features: [featureExample],
    })

    expect(definition.props).toEqual([
      'formId',
      'labelSrOnly',
      'labelPlaceholder',
      'internal',
      'example',
    ])
    expect(definition.features).toEqual([
      translateWrapperProps,
      hideField,
      addBlurEvent,
      featureExample,
    ])
  })
})
