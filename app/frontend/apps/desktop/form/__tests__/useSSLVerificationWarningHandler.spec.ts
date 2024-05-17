// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { type Ref } from 'vue'

import {
  FormHandlerExecution,
  type ChangedField,
  type FormHandlerFunctionData,
  type FormHandlerFunctionReactivity,
  type FormValues,
  type FormSchemaField,
} from '#shared/components/Form/types.ts'

import { useSSLVerificationWarningHandler } from '../composables/useSSLVerificationWarningHandler.ts'

import type { FormKitNode } from '@formkit/core'
import type { Except, SetOptional } from 'type-fest'

const getReactivity = (
  changeFields?: Ref<Record<string, Partial<FormSchemaField>>>,
  fields?: Record<
    string,
    {
      show: boolean
      updateFields: boolean
      props: Except<
        SetOptional<FormSchemaField, 'type'>,
        'show' | 'props' | 'updateFields' | 'relation'
      >
    }
  >,
  values?: Record<string, unknown>,
) =>
  ({
    changeFields,
    schemaData: {
      fields: {
        ...fields,
      },
      ...values,
    },
    updateSchemaDataField: () => {},
  }) as unknown as FormHandlerFunctionReactivity

const getData = (changedField?: ChangedField, values?: FormValues) => {
  const mockedSet = vi.fn()
  const mockedRemove = vi.fn()

  return {
    data: {
      formNode: {
        store: {
          set: mockedSet,
          remove: mockedRemove,
        },
        on: vi.fn(),
      } as unknown as FormKitNode,
      changedField,
      values,
      getNodeByName: vi.fn(),
      findNodeByName: vi.fn(),
    } as FormHandlerFunctionData,
    mockedSet,
    mockedRemove,
  }
}

describe('useSSLVerificationWarningHandler callback', () => {
  it('sets warning when sslVerify is turned off (initial)', async () => {
    const { callback } = useSSLVerificationWarningHandler()

    const reactivity = getReactivity(undefined, {
      sslVerify: {
        show: true,
        updateFields: false,
        props: { name: 'sslVerify', value: false },
      },
    })

    const { data, mockedRemove, mockedSet } = getData(undefined, {
      sslVerify: false,
    })

    callback(FormHandlerExecution.InitialSettled, reactivity, data)

    expect(mockedSet).toHaveBeenCalledWith({
      blocking: false,
      key: 'sslVerificationWarning',
      meta: {},
      type: 'warning',
      value:
        'Turning off SSL verification is a security risk and should be used only temporary. Use this option at your own risk!',
      visible: true,
    })

    expect(mockedRemove).not.toBeCalled()
  })

  it('sets warning when sslVerify is turned off (change)', async () => {
    const { callback } = useSSLVerificationWarningHandler()

    const reactivity = getReactivity(undefined, {
      sslVerify: {
        show: true,
        updateFields: false,
        props: { name: 'sslVerify', value: true },
      },
    })

    const { data, mockedRemove, mockedSet } = getData(
      {
        name: 'sslVerify',
        newValue: false,
        oldValue: true,
      },
      { sslVerify: true },
    )

    callback(FormHandlerExecution.FieldChange, reactivity, data)

    expect(mockedSet).toHaveBeenCalledWith({
      blocking: false,
      key: 'sslVerificationWarning',
      meta: {},
      type: 'warning',
      value:
        'Turning off SSL verification is a security risk and should be used only temporary. Use this option at your own risk!',
      visible: true,
    })

    expect(mockedRemove).not.toBeCalled()
  })

  it('clears warning when sslVerify is turned on (change)', async () => {
    const { callback } = useSSLVerificationWarningHandler()

    const reactivity = getReactivity(undefined, {
      sslVerify: {
        show: true,
        updateFields: false,
        props: { name: 'sslVerify', value: false },
      },
    })

    const { data, mockedRemove, mockedSet } = getData(
      {
        name: 'sslVerify',
        newValue: true,
        oldValue: false,
      },
      { sslVerify: false },
    )

    callback(FormHandlerExecution.FieldChange, reactivity, data)

    expect(mockedSet).not.toBeCalled()
    expect(mockedRemove).toBeCalledWith('sslVerificationWarning')
  })

  it('clears warning when sslVerify is disabled', async () => {
    const { callback } = useSSLVerificationWarningHandler()

    const reactivity = getReactivity(undefined, {
      sslVerify: {
        show: true,
        updateFields: false,
        props: { disabled: true, name: 'sslVerify', value: false },
      },
    })

    const { data, mockedRemove, mockedSet } = getData(
      {
        name: 'sslVerify',
        newValue: true,
        oldValue: false,
      },
      { sslVerify: false },
    )

    callback(FormHandlerExecution.FieldChange, reactivity, data)

    expect(mockedSet).not.toBeCalled()
    expect(mockedRemove).toBeCalledWith('sslVerificationWarning')
  })

  it('sets warning when sslVerify is enabled', async () => {
    const { callback } = useSSLVerificationWarningHandler()

    const reactivity = getReactivity(undefined, {
      sslVerify: {
        show: true,
        updateFields: false,
        props: { disabled: false, name: 'sslVerify', value: true },
      },
    })

    const { data, mockedRemove, mockedSet } = getData(
      {
        name: 'sslVerify',
        newValue: false,
        oldValue: true,
      },
      { sslVerify: true },
    )

    callback(FormHandlerExecution.FieldChange, reactivity, data)

    expect(mockedSet).toHaveBeenCalledWith({
      blocking: false,
      key: 'sslVerificationWarning',
      meta: {},
      type: 'warning',
      value:
        'Turning off SSL verification is a security risk and should be used only temporary. Use this option at your own risk!',
      visible: true,
    })

    expect(mockedRemove).not.toBeCalled()
  })

  it('does not execute when sslVerify is not present', async () => {
    const { callback } = useSSLVerificationWarningHandler()

    const reactivity = getReactivity()
    const { data, mockedRemove, mockedSet } = getData()

    callback(FormHandlerExecution.InitialSettled, reactivity, data)

    expect(mockedSet).not.toBeCalled()
    expect(mockedRemove).not.toBeCalled()
  })

  it('does not execute when another field is changed', async () => {
    const { callback } = useSSLVerificationWarningHandler()

    const reactivity = getReactivity(undefined, {
      sslVerify: {
        show: true,
        updateFields: false,
        props: { name: 'sslVerify', value: false },
      },
    })

    const { data, mockedRemove, mockedSet } = getData(
      {
        name: 'foobar',
        newValue: false,
        oldValue: true,
      },
      { sslVerify: false },
    )

    callback(FormHandlerExecution.FieldChange, reactivity, data)

    expect(mockedSet).not.toBeCalled()
    expect(mockedRemove).not.toBeCalled()
  })
})
