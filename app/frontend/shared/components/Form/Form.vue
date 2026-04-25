<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { getNode, createMessage } from '@formkit/core'
import { FormKit, FormKitMessages, FormKitSchema } from '@formkit/vue'
import { refDebounced, watchOnce } from '@vueuse/shared'
import { isEqual, cloneDeep, merge, isEmpty, isObject } from 'lodash-es'
import {
  useTemplateRef,
  computed,
  ref,
  nextTick,
  shallowRef,
  reactive,
  toRef,
  watch,
  markRaw,
  useSlots,
  onBeforeUnmount,
  effectScope,
} from 'vue'

import { NotificationTypes } from '#shared/components/CommonNotifications/types.ts'
import { useNotifications } from '#shared/components/CommonNotifications/useNotifications.ts'
import { useObjectAttributeFormFields } from '#shared/entities/object-attributes/composables/useObjectAttributeFormFields.ts'
import { useObjectAttributeLoadFormFields } from '#shared/entities/object-attributes/composables/useObjectAttributeLoadFormFields.ts'
import { flattenObjectAttributeValues } from '#shared/entities/object-attributes/utils.ts'
import UserError from '#shared/errors/UserError.ts'
import { extractEntityIds } from '#shared/form/utils/entity.ts'
import type {
  EnumObjectManagerObjects,
  EnumFormUpdaterId,
  FormUpdaterRelationField,
  FormUpdaterQuery,
  FormUpdaterQueryVariables,
  ObjectAttributeValue,
  FormUpdaterMetaInput,
  FormUpdaterChangedFieldInput,
} from '#shared/graphql/types.ts'
import { I18N, i18n } from '#shared/i18n.ts'
import { QueryHandler } from '#shared/server/apollo/handler/index.ts'
import type { EntityObject } from '#shared/types/entity.ts'
import type {
  FormUpdaterAdditionalParams,
  FormUpdaterOptions,
  FormUpdaterTrigger,
} from '#shared/types/form.ts'
import { camelize } from '#shared/utils/formatter.ts'
import { getFirstFocusableElement } from '#shared/utils/getFocusableElements.ts'
import getUuid from '#shared/utils/getUuid.ts'
import log from '#shared/utils/log.ts'
import { markup } from '#shared/utils/markup.ts'
import testFlags from '#shared/utils/testFlags.ts'

import FormGroup from './FormGroup.vue'
import FormLayout from './FormLayout.vue'
import { useFormUpdaterQuery } from './graphql/queries/formUpdater.api.ts'
import { getFormClasses } from './initializeFormClasses.ts'
import addTranslationFunctionPlugin from './plugins/addTranslationFunctionPlugin.ts'
import initializeFieldInitialValuesCleanupPlugin from './plugins/initializeFieldInitialValuesCleanupPlugin.ts'
import { FormHandlerExecution, FormValidationVisibility } from './types.ts'
import { getNodeByName as getFormkitFieldNode, getNodeId, setErrors } from './utils.ts'

import type {
  ChangedField,
  FormSubmitData,
  FormFieldAdditionalProps,
  FormFieldValue,
  FormHandler,
  FormHandlerFunction,
  FormOnSubmitFunctionCallbacks,
  FormSchemaField,
  FormSchemaLayout,
  FormSchemaNode,
  FormValues,
  ReactiveFormSchemData,
  FormResetData,
  FormResetOptions,
} from './types.ts'
import type {
  FormKitPlugin,
  FormKitSchemaNode,
  FormKitSchemaCondition,
  FormKitNode,
  FormKitClasses,
  FormKitSchemaDOMNode,
  FormKitSchemaComponent,
  FormKitMessageProps,
} from '@formkit/core'
import type { Except, SetRequired } from 'type-fest'
import type { Component, Ref, SetupContext } from 'vue'

// oxlint-disable no-use-before-define
export interface Props {
  id?: string
  schema?: FormSchemaNode[]
  schemaData?: Except<ReactiveFormSchemData, 'fields' | 'flags'>
  schemaComponentLibrary?: Record<string, Component>
  handlers?: FormHandler[]
  changeFields?: Record<string, Partial<FormSchemaField>>
  formId?: string
  formUpdaterId?: EnumFormUpdaterId
  formUpdaterInitialOnly?: boolean
  formUpdaterAdditionalParams?: FormUpdaterAdditionalParams
  // Maybe in the future this is no longer needed, when FormKit supports group
  // without value grouping below group name (https://github.com/formkit/formkit/issues/461).
  flattenFormGroups?: string[]
  hiddenFormGroups?: string[]
  formKitPlugins?: FormKitPlugin[]
  formKitSectionsSchema?: Record<string, Partial<FormKitSchemaNode> | FormKitSchemaCondition>
  class?: FormKitClasses | string | Record<string, boolean>
  formClass?: string | Record<string, string>

  // Can be used to define initial values on frontend side and fetched schema from the server.
  initialValues?: Partial<FormValues>
  initialEntityObject?: EntityObject

  validationVisibility?: FormValidationVisibility
  disabled?: boolean
  shouldAutofocus?: boolean

  // Some special properties for working with object attribute fields inside of a form schema.
  useObjectAttributes?: boolean
  objectAttributeSkippedFields?: string[]

  clearValuesAfterSubmit?: boolean

  // Implement the submit in this way, because we need to react on async usage of the submit function.
  // Don't forget that to submit a form with "Enter" key, you need to add a button with type="submit" inside of the form.
  // Or to have a button outside of form with "form" attribite with the same value as the form id.
  // After this method is called, form resets its values and state. If you need to call something afterwards,
  // like make route navigation, you can return a function from the submit handler, which will be called after the form reset.
  // When you return "false" inside the submit function the handling will be stopped.
  onSubmit?: (
    values: FormSubmitData,
    flags?: Record<string, boolean>,
  ) =>
    | Promise<void | (() => void) | FormOnSubmitFunctionCallbacks | false>
    | void
    | (() => void)
    | FormOnSubmitFunctionCallbacks
    | false
}

const props = withDefaults(defineProps<Props>(), {
  schema: () => {
    return []
  },
  changeFields: () => {
    return reactive({})
  },
  validationVisibility: FormValidationVisibility.Submit,
  useObjectAttributes: false,
})

const formId = props.formId ? props.formId : getUuid()

const slots: SetupContext['slots'] = useSlots()

const hasSchema = computed(() => Boolean(slots.default) || Boolean(props.schema))
const formSchemaInitialized = ref(false)

if (!hasSchema.value) {
  log.error('No schema defined. Please use the schema prop or the default slot for the schema.')
}

// Rename prop 'class' for usage in the template, because of reserved word
const localClass = toRef(props, 'class')

const emit = defineEmits<{
  changed: [
    fieldName: string,
    newValue: FormFieldValue,
    oldValue: FormFieldValue,
    formUpdaterValueChange: boolean,
  ]
  node: [node: FormKitNode]
  settled: []
  focused: []
}>()

const showInitialLoadingAnimation = ref(false)
const debouncedShowInitialLoadingAnimation = refDebounced(showInitialLoadingAnimation, 300)

const formKitInitialNodesSettled = ref(false)
const formInitialSettled = ref(false)
const formResetRunning = ref(false)
const formNode: Ref<FormKitNode | undefined> = ref()
const formNodeGroups = computed(() => {
  if (!formNode.value) return

  return formNode.value.children
    .filter((child) => child.type === 'group')
    .map((child) => child.name)
})
const formElement = useTemplateRef('form')

const changeFields = toRef(props, 'changeFields')

const currentCreatedFormFields = new Set<string>()
const updaterChangedFields = new Set<string>()
const changeInitialValue = new Map<string, FormFieldValue>()

const getNodeByName = (id: string) => {
  return getFormkitFieldNode(formId, id)
}

const findNodeByName = (name: string) => {
  return formNode.value?.find(name, 'name')
}

const autofocusFirstInput = (node: FormKitNode) => {
  nextTick(() => {
    const firstInput = getFirstFocusableElement(formElement.value)

    firstInput?.focus()
    firstInput?.scrollIntoView({ block: 'nearest' })

    const formName = node.context?.id || node.name
    testFlags.set(`${formName}.focused`)
    emit('focused')
  })
}

const setInitialEntityObjectToContext = (node: FormKitNode, object = props.initialEntityObject) => {
  if (node.context && object) {
    node.context.initialEntityObject = object
  }
}

const setFormNode = (node: FormKitNode) => {
  formNode.value = node

  setInitialEntityObjectToContext(node)

  node.settled.then(() => {
    showInitialLoadingAnimation.value = false

    nextTick(() => {
      changeInitialValue.forEach((value, fieldName) => {
        findNodeByName(fieldName)?.input(value, false)
      })

      changeInitialValue.clear()

      formKitInitialNodesSettled.value = true
      if (formNode.value) formNode.value.props._formSettled = true

      // Reset directly after the initial request.
      updaterChangedFields.clear()

      const formName = node.context?.id || node.name
      testFlags.set(`${formName}.settled`)
      emit('settled')

      formInitialSettled.value = true

      nextTick(() => {
        executeFormHandler(FormHandlerExecution.InitialSettled, values.value)

        if (props.shouldAutofocus) autofocusFirstInput(node)
      })
    })
  })

  node.on('autofocus', () => autofocusFirstInput(node))

  emit('node', node)
}

const formNodeContext = computed(() => formNode.value?.context)

// Build the flat value when its requested for specific form groups.
const getFlatValues = (
  values: FormValues,
  flattenFormGroups?: string[],
  hiddenFormGroups?: string[],
) => {
  if (!flattenFormGroups && !hiddenFormGroups) return values

  const flatValues = {
    ...values,
  }

  hiddenFormGroups?.forEach((formGroup) => {
    delete flatValues[formGroup]
  })

  flattenFormGroups?.forEach((formGroup) => {
    Object.assign(flatValues, flatValues[formGroup])
    delete flatValues[formGroup]
  })

  return flatValues
}

// Use the node context value, instead of the v-model, because of performance reason.
const values = computed<FormValues>(() => {
  if (!formNodeContext.value) {
    return {}
  }

  return getFlatValues(formNodeContext.value.value, props.flattenFormGroups, props.hiddenFormGroups)
})

const relationFields: FormUpdaterRelationField[] = []
const relationFieldBelongsToObjectField: Record<string, string> = {}

const formUpdaterProcessing = computed(() => !!formNode.value?.context?.state.formUpdaterProcessing)

const uploadProcessing = computed(() => !!formNode.value?.context?.state.uploadProcessing)

let delayedSubmit = false
const onSubmitRaw = () => {
  if (formUpdaterProcessing.value || uploadProcessing.value) {
    delayedSubmit = true
  }
}

const afterSubmitReset = (values: FormSubmitData) => {
  if (!formNode.value) return

  if (props.clearValuesAfterSubmit) {
    formNode.value.reset()
  } else {
    formNode.value.reset(values)
  }
}

const afterSubmitHandling = (
  submitReturn: void | (() => void) | FormOnSubmitFunctionCallbacks,
  values: FormSubmitData,
) => {
  if (!formNode.value) return

  schemaData.flags = {}

  if (isObject(submitReturn) && ('reset' in submitReturn || 'finally' in submitReturn)) {
    if (submitReturn.reset) {
      submitReturn.reset(values, formNode.value.value as FormValues)
    } else {
      afterSubmitReset(values)
    }

    // oxlint-disable-next-line eslint-plugin-promise(valid-params)
    submitReturn.finally?.()

    return
  }

  afterSubmitReset(values)

  if (typeof submitReturn === 'function') submitReturn()
}

const onSubmit = (values: FormSubmitData) => {
  // Needs to be checked, because the 'onSubmit' function is not required.
  if (!props.onSubmit) return undefined

  const flatValues = getFlatValues(values, props.flattenFormGroups, props.hiddenFormGroups)

  formNode.value?.clearErrors()

  const submitResult = props.onSubmit(flatValues, schemaData.flags)

  if (submitResult !== undefined && submitResult === false) return

  if (submitResult instanceof Promise) {
    return submitResult
      .then((result) => {
        // When false was returned the submit was skipped.
        if (result !== undefined && result === false) return

        // it's possible to destroy Form before this is called and the reset should not run when errors exists.
        if (!formNode.value || formNode.value.context?.state.errors) return

        afterSubmitHandling(result, values)
      })
      .catch((errors: UserError) => {
        if (formNode.value) setErrors(formNode.value, errors)
      })
  }

  afterSubmitHandling(submitResult, values)
}

let formUpdaterQueryHandler: QueryHandler<FormUpdaterQuery, FormUpdaterQueryVariables>

const triggerFormUpdater = (options?: FormUpdaterOptions) => {
  handlesFormUpdater('manual', undefined, undefined, options)
}

const delayedSubmitPlugin = (node: FormKitNode) => {
  node.on('message-removed', async ({ payload }) => {
    if (
      (payload.key === 'formUpdaterProcessing' || payload.key === 'uploadProcessing') &&
      delayedSubmit
    ) {
      // We need to wait on the "next tick", so that the validation for updated fields is ready.
      setTimeout(() => {
        delayedSubmit = false
        node.submit()
      }, 0)
    }
  })

  return false
}

const localFormKitPlugins = computed(() => {
  return [
    initializeFieldInitialValuesCleanupPlugin,
    delayedSubmitPlugin,
    addTranslationFunctionPlugin,
    ...(props.formKitPlugins || []),
  ]
})

const formConfig = computed(() => {
  return {
    validationVisibility: props.validationVisibility,
  }
})

// Define the additional component library for the used components which are not form fields.
const additionalComponentLibrary = {
  FormLayout: markRaw(FormLayout),
  FormGroup: markRaw(FormGroup),
  ...props.schemaComponentLibrary,
}

// Define the static schema, which will be filled with the real fields from the `schemaData`.
const staticSchema = ref<FormKitSchemaNode[]>([])

const fixedAndSkippedFields: string[] = []

const schemaData = reactive<ReactiveFormSchemData>({
  fields: {},
  flags: {},
  values,
  // Helper function to translate directly with the formkit syntax.
  // Wrapper is neded, because of unexpected side effects.
  t: (source: Parameters<I18N['t']>[0], ...args: Array<Parameters<I18N['t']>[1]>) => {
    return i18n.t(source, ...args)
  },
  markup,
  ...props.schemaData,
})

const schemaDataFlags = computed(() => schemaData.flags)

const internalFieldCamelizeName: Record<string, string> = {}

let initialEntityObjectAttributeMap: Record<string, FormFieldValue> = {}
const setInitialEntityObjectAttributeMap = (initialEntityObject = props.initialEntityObject) => {
  if (isEmpty(initialEntityObject)) return

  const { objectAttributeValues } = initialEntityObject

  if (!objectAttributeValues) return

  // Reduce object attribute values to flat structure
  initialEntityObjectAttributeMap =
    flattenObjectAttributeValues<FormFieldValue>(objectAttributeValues)
}

// Initialize the initial entity object attribute map during the setup in a static way.
// It will maybe be updated later, when the resetForm is used with a different entity object.
setInitialEntityObjectAttributeMap()

const getInitialEntityObjectValue = (
  fieldName: string,
  initialEntityObject = props.initialEntityObject,
): FormFieldValue => {
  if (isEmpty(initialEntityObject)) return undefined

  let value: FormFieldValue
  if (relationFieldBelongsToObjectField[fieldName]) {
    const belongsToObject = initialEntityObject[relationFieldBelongsToObjectField[fieldName]]
    value = extractEntityIds(belongsToObject)
  }

  if (!value) {
    const targetFieldName = internalFieldCamelizeName[fieldName] || fieldName

    value =
      targetFieldName in initialEntityObjectAttributeMap
        ? initialEntityObjectAttributeMap[targetFieldName]
        : initialEntityObject[targetFieldName]
  }

  return value
}

const getResetFormValues = (
  rootNode: FormKitNode,
  values?: FormValues,
  object?: EntityObject,
  groupNode?: FormKitNode,
  resetDirty = true,
) => {
  const resetValues: FormValues = {}
  const dirtyNodes: FormKitNode[] = []
  const dirtyValues: FormValues = {}

  const setResetFormValue = (name: string, value: FormFieldValue, parentName?: string) => {
    if (parentName) {
      resetValues[parentName] ||= {}
      ;(resetValues[parentName] as Record<string, FormFieldValue>)[name] = value
      return
    }

    resetValues[name] = value
  }

  const checkValue = (name: string, values: FormValues, parentName?: string) => {
    if (name in values) {
      setResetFormValue(name, values[name], parentName)

      return true
    }
    if (parentName && parentName in values && values[parentName]) {
      const value = (values[parentName] as Record<string, FormFieldValue>)[name]

      setResetFormValue(name, value, parentName)

      return true
    }

    return false
  }

  const checkObjectValue = (name: string, object: EntityObject, parentName?: string) => {
    const objectValue = getInitialEntityObjectValue(name, object)
    if (objectValue !== undefined) {
      setResetFormValue(name, objectValue, parentName)

      return true
    }

    return false
  }

  Object.entries(schemaData.fields).forEach(([field, { props }]) => {
    const formElement = props.id ? getNode(props.id) : getNodeByName(props.name)

    if (!formElement) return

    let parentName = ''
    if (formElement.parent && formElement.parent.name !== rootNode.name) {
      parentName = formElement.parent.name
    }

    // Do not use the parentName, when we are in group node reset context.
    const groupName = groupNode?.name
    if (groupName) {
      if (parentName !== groupName) return
      parentName = ''
    }

    if (!resetDirty && formElement.context?.state.dirty) {
      dirtyNodes.push(formElement)
      dirtyValues[field] = formElement._value as FormFieldValue
    }

    // We should only do something related to the given values, when something was given.
    if (values && checkValue(field, values, parentName)) return

    if (object) {
      checkObjectValue(field, object, parentName)
    }
  })

  return {
    dirtyNodes,
    dirtyValues,
    resetValues,
  }
}

const resetForm = (data: FormResetData = {}, options: FormResetOptions = {}) => {
  if (!formNode.value) return

  const { object, values: valuesForReset } = data
  const { resetDirty = true, resetFlags = true, groupNode } = options

  formResetRunning.value = true

  if (resetFlags) {
    // Preserve flags as false instead of setting to empty hash
    Object.keys(schemaData.flags).forEach((key) => {
      schemaData.flags[key] = false
    })
  }

  const rootNode = formNode.value

  // When we have given reset values and we have a form with groups on the first level, we check
  // if all groups are given as new initial values and if not we using the existing initial values
  // from the group inside the form.
  if (!groupNode && formNodeGroups.value && !isEmpty(valuesForReset)) {
    const nonGroupKeys = Object.keys(valuesForReset).filter(
      (key) => !formNodeGroups.value?.includes(key),
    )

    formNodeGroups.value.forEach((groupName: string) => {
      if (
        (!props.flattenFormGroups ||
          !props.flattenFormGroups.includes(groupName) ||
          nonGroupKeys.length === 0) &&
        !(groupName in valuesForReset)
      ) {
        valuesForReset[groupName] = rootNode.props._init?.[groupName] || {}
      }
    })
  }

  if (object) {
    setInitialEntityObjectAttributeMap(object)
    setInitialEntityObjectToContext(rootNode, object)
  }

  const { dirtyNodes, dirtyValues, resetValues } = getResetFormValues(
    rootNode,
    valuesForReset,
    object,
    groupNode,
    resetDirty,
  )

  ;(groupNode || rootNode)?.reset(Object.keys(resetValues).length ? resetValues : undefined)

  // keep dirty nodes as dirty
  dirtyNodes.forEach((node) => {
    node.input(dirtyValues[node.name], false)
  })

  nextTick(() => {
    formResetRunning.value = false

    // Trigger the formUpdater, when the reset is done.
    handlesFormUpdater(resetDirty ? 'form-reset' : 'form-refresh')
  })
}

const localInitialValues: FormValues = { ...props.initialValues }

const initializeFieldRelation = (
  fieldName: string,
  relation: FormSchemaField['relation'],
  belongsToObjectField?: string,
) => {
  if (relation) {
    relationFields.push({
      name: fieldName,
      relation: relation.type,
      filterIds: relation.filterIds,
    })
  }

  if (belongsToObjectField) {
    relationFieldBelongsToObjectField[fieldName] = belongsToObjectField
  }
}

const setInternalField = (fieldName: string, internal: boolean) => {
  if (!internal) return

  internalFieldCamelizeName[fieldName] = camelize(fieldName)
}

const updateSchemaLink = (specificProps: FormFieldAdditionalProps, fieldName: string) => {
  // native fields don't have link attribute, and we don't have a way to get rendered link from graphql
  const values = (props.initialEntityObject?.objectAttributeValues || []) as ObjectAttributeValue[]
  const attribute = values.find(({ attribute }) => attribute.name === fieldName)
  if (!attribute?.renderedLink) return
  specificProps.link = attribute?.renderedLink
}

const updateSchemaDataField = (
  field: FormSchemaField | SetRequired<Partial<FormSchemaField>, 'name'>,
) => {
  const {
    show,
    updateFields,
    relation,
    if: staticCondition,
    props: specificProps = {},
    ...fieldProps
  } = field
  const showWithStaticCondition = Boolean(
    staticCondition || schemaData.fields[field.name]?.staticCondition,
  )
  const showField =
    show ?? schemaData.fields[field.name]?.show ?? (showWithStaticCondition ? undefined : true)

  // Special handling for the disabled prop, so that the form can handle also
  // the disable state from outside.
  if ('disabled' in fieldProps && !fieldProps.disabled) {
    fieldProps.disabled = undefined
  }

  updateSchemaLink(fieldProps, field.name)

  if (schemaData.fields[field.name]) {
    schemaData.fields[field.name] = {
      show: showField,
      updateFields: !!updateFields,
      staticCondition: showWithStaticCondition,
      props: Object.assign(schemaData.fields[field.name].props, fieldProps, specificProps),
    }
  } else {
    initializeFieldRelation(field.name, relation, specificProps?.belongsToObjectField)

    setInternalField(field.name, Boolean(fieldProps.internal))

    const combinedFieldProps = Object.assign(fieldProps, specificProps)

    // Select the correct initial value (at this time localInitialValues has not already the information
    // from the initial entity object, so we need to check it manually).
    if (field.name in localInitialValues) {
      combinedFieldProps.value = localInitialValues[field.name]
    } else {
      const initialEntityOjectValue = getInitialEntityObjectValue(field.name)
      combinedFieldProps.value =
        initialEntityOjectValue !== undefined ? initialEntityOjectValue : combinedFieldProps.value
    }

    // Save current initial value for later usage.
    localInitialValues[field.name] = combinedFieldProps.value

    schemaData.fields[field.name] = {
      show: showField,
      updateFields: !!updateFields,
      staticCondition: showWithStaticCondition,
      props: combinedFieldProps,
    }
  }
}

// We have some flags which are used for some detection related to some additional logic.
// - formUpdaterValueChange: This flag is set when the value is changed by the form updater to avoid re-trigger of
// the form updater (this is needed because "updaterChangedFields" can already be reseted again, but value changes can be delayed).
// - pendingValueUpdate: This flag is set when the value is changed by the form updater and the value is not yet updated in
// the form, to avoid some code exection especially in select fields.
// - updaterChangedFields: This flag is set when the field is changed by the form updater, to avoid re-trigger of the form updater.
const updateChangedFields = (
  changedFields: Record<string, Partial<FormSchemaField>>,
  changesCanTriggerFormUpdater = false,
) => {
  const handleUpdatedInitialFieldValue = (
    fieldName: string,
    value: FormFieldValue,
    directly: boolean,
    field: Partial<FormSchemaField>,
  ) => {
    if (value === undefined) return

    if (directly) {
      field.value = value
    } else if (!formKitInitialNodesSettled.value) {
      changeInitialValue.set(fieldName, value)
    }
  }

  Object.keys(changedFields).forEach(async (fieldName) => {
    if (!schemaData.fields[fieldName]) return

    const { initialValue, value, ...changedFieldProps } = changedFields[fieldName]

    const field: SetRequired<Partial<FormSchemaField>, 'name'> = {
      ...changedFieldProps,
      name: fieldName,
    }

    const showField = Boolean(!schemaData.fields[fieldName].show && field.show)
    const staticShowCondition = schemaData.fields[fieldName].staticCondition

    // For post-initial show-field cases, `value` alone must not become the dirty
    // baseline — only an explicit `initialValue` represents the real initial.
    // Reuse the pendingValueUpdate path to apply `value` via node.input() after
    // the field is rendered (which correctly makes it dirty relative to `_init`).
    const pendingValueUpdate =
      (!showField || formKitInitialNodesSettled.value) &&
      (!staticShowCondition || (staticShowCondition && currentCreatedFormFields.has(fieldName))) &&
      value !== undefined &&
      !isEqual(value, values.value[fieldName])

    if (pendingValueUpdate) {
      field.formUpdaterValueChange = !changesCanTriggerFormUpdater
      field.pendingValueUpdate = true
    }

    // This happens for the initial updater, when the form is not settled yet or the field was not rendered yet.
    // In this case we need to remember the changes and do it afterwards after the form is settled the first time.
    // Sometimes the value from the server is the "real" initial value, for this the `initialValue` can be used.
    handleUpdatedInitialFieldValue(
      fieldName,
      // For post-initial show-field: only `initialValue` sets the dirty baseline in the
      // schema. If absent, the early-return in handleUpdatedInitialFieldValue leaves
      // field.value unset and the plugin captures the natural field default as _init.
      // During initial load the original `value ?? initialValue` behaviour is kept.
      showField && formKitInitialNodesSettled.value ? initialValue : (value ?? initialValue),
      showField ||
        initialValue !== undefined ||
        !!(
          (staticShowCondition ||
            (schemaData.fields[fieldName].show && formKitInitialNodesSettled.value)) &&
          !currentCreatedFormFields.has(fieldName)
        ),
      field,
    )

    // When a field will be visible with the update call, we need to wait before on a settled form, before we
    // continue (so that we have all values present inside the form).
    // This situtation can happen, when the form is used very fast.
    if (formKitInitialNodesSettled.value && showField && !formNode.value?.isSettled) {
      await formNode.value?.settled
    }

    // Only add the field when changes can not trigger additional form updater requests.
    if (!changesCanTriggerFormUpdater) updaterChangedFields.add(fieldName)

    updateSchemaDataField(field)

    if (!formKitInitialNodesSettled.value) return

    if (pendingValueUpdate) {
      // Resolve the node inside nextTick so newly shown fields (created by
      // updateSchemaDataField above) are already registered by FormKit.
      nextTick(() => {
        const node = field.id ? getNode(field.id) : getNodeByName(fieldName)

        if (showField && node) {
          // For newly shown fields, the node's initial empty-value commit fires
          // before this tick and resets formUpdaterValueChange to false. Re-apply
          // it so our input is not mistaken for a user change.
          node.props.formUpdaterValueChange = true

          // node.settled guarantees hasTicked=true inside FormKit, so the commit
          // from node.input() will automatically trigger dirty re-evaluation.
          // The plugin already captured _init synchronously during field creation,
          // before settled resolves, so the baseline is correct.
          node.settled.then(() => node.input(value, false))
        } else {
          node?.input(value, false)
        }
      })
    }
  })

  nextTick(() => {
    updaterChangedFields.clear()
    formNode.value?.store.remove('formUpdaterProcessing')
  })
}

const formHandlerExecution: Record<FormHandlerExecution, FormHandlerFunction[]> = {
  [FormHandlerExecution.Initial]: [],
  [FormHandlerExecution.InitialSettled]: [],
  [FormHandlerExecution.FieldChange]: [],
}
if (props.handlers) {
  props.handlers.forEach((handler) => {
    Object.values(FormHandlerExecution).forEach((execution) => {
      if (handler.execution.includes(execution)) {
        formHandlerExecution[execution].push(handler.callback)
      }
    })
  })
}

const executeFormHandler = (
  execution: FormHandlerExecution,
  currentValues: FormValues,
  changedField?: ChangedField,
  formUpdaterData?: FormUpdaterQuery['formUpdater'],
) => {
  if (formHandlerExecution[execution].length === 0) return

  formHandlerExecution[execution].forEach((handler) => {
    handler(
      execution,
      {
        changeFields,
        updateSchemaDataField,
        schemaData,
      },
      {
        formNode: formNode.value,
        getNodeByName,
        findNodeByName,
        values: currentValues,
        changedField,
        initialEntityObject: props.initialEntityObject,
        formUpdaterData,
      },
    )
  })
}

const formUpdaterVariables = shallowRef<FormUpdaterQueryVariables>()
let nextFormUpdaterVariables: Maybe<FormUpdaterQueryVariables>
const executeFormUpdaterRefetch = () => {
  if (!nextFormUpdaterVariables) return

  formNode.value?.store.set(
    createMessage({
      blocking: true,
      key: 'formUpdaterProcessing',
      value: true,
      visible: false,
    }),
  )

  formUpdaterVariables.value = nextFormUpdaterVariables

  // Reset the next variables so that it's not triggered a second time.
  nextFormUpdaterVariables = null
}

const updateDataWithChangedField = (
  data: FormValues,
  changedField: FormUpdaterChangedFieldInput,
  changedFieldNode?: FormKitNode,
) => {
  const parentName = changedFieldNode?.parent?.name

  // Currently we are only supporting one level.
  if (
    formNode.value &&
    parentName &&
    parentName !== formNode.value.name &&
    (!props.flattenFormGroups || !props.flattenFormGroups.includes(parentName))
  ) {
    data[parentName] ||= {}
    ;(data[parentName] as Record<string, FormFieldValue>)[changedField.name] = changedField.newValue
  } else {
    data[changedField.name] = changedField.newValue
  }
}

const handlesFormUpdater = (
  trigger: FormUpdaterTrigger,
  changedField?: FormUpdaterChangedFieldInput,
  changedFieldNode?: FormKitNode,
  options?: FormUpdaterOptions,
) => {
  if (!props.formUpdaterId || !formUpdaterQueryHandler) return
  // When formUpdaterInitial is set, trigger only on initial rendering and when the form was reseted.
  if (
    trigger !== 'manual' &&
    trigger !== 'form-reset' &&
    trigger !== 'form-refresh' &&
    (!changedField || props.formUpdaterInitialOnly)
  )
    return

  // Check if we already have a pending formUpdater request in the same tick
  if (nextFormUpdaterVariables && changedField) {
    // Add this change to additionalChangedFields instead of overriding the primary one
    if (!nextFormUpdaterVariables.meta.additionalChangedFields) {
      nextFormUpdaterVariables.meta.additionalChangedFields = []
    }
    nextFormUpdaterVariables.meta.additionalChangedFields.push(changedField)

    // Also update the data object to include the new value
    updateDataWithChangedField(nextFormUpdaterVariables.data, changedField, changedFieldNode)

    return
  }

  const meta: FormUpdaterMetaInput = {
    // We need a unique requestId, so that the query will always be executed on changes, also when the variables
    // are the same until the last request, because it could be that core workflow is setting a value back.
    requestId: getUuid(),
    formId,
    additionalData: {
      ...props.formUpdaterAdditionalParams,
      ...options?.additionalParams,
    },
  }

  if (options?.includeDirtyFields) {
    const dirtyFields: string[] = []

    Object.entries(schemaData.fields).forEach(([field, { props }]) => {
      const formElement = props.id ? getNode(props.id) : getNodeByName(props.name)

      if (!formElement) return

      if (formElement.context?.state.dirty) {
        dirtyFields.push(field)
      }
    })

    meta.dirtyFields = dirtyFields
  }

  const data: FormValues = {
    ...values.value,
  }

  if (trigger === 'form-reset') {
    meta.reset = true
  } else if (changedField) {
    meta.changedField = changedField
    updateDataWithChangedField(data, changedField, changedFieldNode)
  }

  // We mark this as raw, because we want no deep reactivity on the form updater query variables.
  nextFormUpdaterVariables = markRaw({
    id: props.initialEntityObject?.id,
    formUpdaterId: props.formUpdaterId,
    data,
    meta,
    relationFields,
  })

  if (trigger !== 'blur') {
    // Execute in next tick to allow same-tick changes to be collected
    nextTick(() => {
      executeFormUpdaterRefetch()
    })
  }
}

const previousValues = new WeakMap<FormKitNode, FormFieldValue>()
const changedInputValueHandling = (inputNode: FormKitNode) => {
  inputNode.on('created', () => {
    currentCreatedFormFields.add(inputNode.name)
  })

  inputNode.on('destroying', () => {
    currentCreatedFormFields.delete(inputNode.name)
  })

  inputNode.on('commit', ({ payload: newValue, origin: node }) => {
    // Get the current information and reset the value again, when it was present.
    const formUpdaterValueChange = node.props.formUpdaterValueChange ?? false
    if (node.props.formUpdaterValueChange) {
      node.props.formUpdaterValueChange = false
    }

    const oldValue = previousValues.get(node)

    if (isEqual(newValue, oldValue)) {
      updaterChangedFields.delete(node.name)
      return
    }

    if (
      !formKitInitialNodesSettled.value ||
      formResetRunning.value ||
      (!currentCreatedFormFields.has(node.name) && !newValue) // It's the initial value commit for the field, when it's not "fully" created yet.
    ) {
      updaterChangedFields.delete(node.name)
      previousValues.set(node, cloneDeep(newValue))
      return
    }

    const changedFieldData: ChangedField = {
      name: node.name,
      newValue,
      oldValue,
    }

    if (
      inputNode.props.triggerFormUpdater &&
      !formUpdaterValueChange &&
      !updaterChangedFields.has(node.name)
    ) {
      handlesFormUpdater(inputNode.props.formUpdaterTrigger, changedFieldData, node)
    }

    emit('changed', node.name, newValue, oldValue, formUpdaterValueChange)
    formNode.value?.emit(`changed:${node.name}`, {
      newValue,
      oldValue,
      fieldNode: node,
      formUpdaterValueChange,
    })
    executeFormHandler(FormHandlerExecution.FieldChange, values.value, {
      ...changedFieldData,
      formUpdaterValueChange,
    })

    updaterChangedFields.delete(node.name)
    previousValues.set(node, cloneDeep(newValue))
  })

  inputNode.on('blur', async () => {
    if (inputNode.props.formUpdaterTrigger !== 'blur') return

    if (!formNode.value?.isSettled) await formNode.value?.settled

    if (nextFormUpdaterVariables) executeFormUpdaterRefetch()
  })

  inputNode.hook.message((payload: FormKitMessageProps, next) => {
    if (payload.key === 'submitted' && formUpdaterProcessing.value) {
      payload.value = false
    }
    return next(payload)
  })

  return false
}

const buildStaticSchema = () => {
  const { getFormFieldSchema, getFormFieldsFromScreen } = useObjectAttributeFormFields(
    fixedAndSkippedFields,
    props.initialEntityObject?.policy,
  )

  const buildFormKitField = (field: FormSchemaField): FormKitSchemaComponent => {
    const fieldId = field.id || getNodeId(formId, field.name)

    const plugins = [changedInputValueHandling]

    if (field.plugins) {
      plugins.push(...field.plugins)
    }

    return {
      $cmp: 'FormKit',
      if: field.if ? field.if : `$fields.${field.name}.show`,
      bind: `$fields.${field.name}.props`,
      props: {
        type: field.type,
        key: fieldId,
        name: field.name,
        id: fieldId,
        formId,
        plugins,
        validationMessages: field.validationMessages,
        validationRules: field.validationRules,
        triggerFormUpdater: field.triggerFormUpdater ?? !!props.formUpdaterId,
      },
    }
  }

  const getLayoutType = (
    layoutNode: FormSchemaLayout,
  ): FormKitSchemaDOMNode | FormKitSchemaComponent => {
    let layoutField: FormKitSchemaDOMNode | FormKitSchemaComponent

    if ('component' in layoutNode) {
      layoutField = {
        $cmp: layoutNode.component,
        ...(layoutNode.if && { if: layoutNode.if }),
        props: layoutNode.props,
      }
    } else {
      layoutField = {
        $el: layoutNode.element,
        ...(layoutNode.if && { if: layoutNode.if }),
        attrs: layoutNode.attrs,
      }
    }

    if (layoutNode.if) {
      layoutField.if = layoutNode.if
    }

    return layoutField
  }

  type ResolveFormSchemaNode = Exclude<FormSchemaNode, string>
  type ResolveFormKitSchemaNode = Exclude<FormKitSchemaNode, string>

  const resolveSchemaNode = (
    node: ResolveFormSchemaNode,
  ): Maybe<ResolveFormKitSchemaNode | ResolveFormKitSchemaNode[]> => {
    if ('isLayout' in node && node.isLayout) {
      return getLayoutType(node)
    }

    if ('isGroupOrList' in node && node.isGroupOrList) {
      const nodeId = `${node.name}-${formId}`

      return {
        $cmp: 'FormKit',
        ...(node.if && { if: node.if }),
        props: {
          type: node.type,
          name: node.name,
          id: nodeId,
          key: node.name,
          plugins: node.plugins,
        },
      }
    }

    if ('object' in node && getFormFieldSchema && getFormFieldsFromScreen) {
      if ('name' in node && node.name && !node.type) {
        const { screen, object, ...fieldNode } = node

        const resolvedField = getFormFieldSchema(fieldNode.name, object, screen)

        if (!resolvedField) return null

        node = {
          ...resolvedField,
          ...fieldNode,
        } as FormSchemaField
      } else if ('screen' in node && !('name' in node)) {
        const resolvedFields = getFormFieldsFromScreen(node.screen, node.object)
        const formKitFields: ResolveFormKitSchemaNode[] = []
        resolvedFields.forEach((screenField) => {
          updateSchemaDataField(screenField)
          formKitFields.push(buildFormKitField(screenField))
        })

        return formKitFields
      }
    }

    updateSchemaDataField(node as FormSchemaField)
    return buildFormKitField(node as FormSchemaField)
  }

  const resolveSchema = (schema: FormSchemaNode[] = props.schema) => {
    return schema.reduce((resolvedSchema: FormKitSchemaNode[], node) => {
      if (typeof node === 'string') {
        resolvedSchema.push(node)
        return resolvedSchema
      }

      const resolvedNode = resolveSchemaNode(node)

      if (!resolvedNode) return resolvedSchema

      if ('children' in node) {
        const childrens = Array.isArray(node.children)
          ? [...resolveSchema(node.children)]
          : node.children

        resolvedSchema.push({
          ...(resolvedNode as Exclude<FormKitSchemaNode, string>),
          children: childrens,
        })
        return resolvedSchema
      }

      if (Array.isArray(resolvedNode)) {
        resolvedSchema.push(...resolvedNode)
      } else {
        resolvedSchema.push(resolvedNode)
      }

      return resolvedSchema
    }, [])
  }

  staticSchema.value = resolveSchema()
}

watchOnce(formKitInitialNodesSettled, () => {
  watch(
    changeFields,
    (newValue) => {
      updateChangedFields(newValue, true)
    },
    {
      deep: true,
    },
  )
})

watch(
  () => props.schemaData,
  () => Object.assign(schemaData, props.schemaData),
  {
    deep: true,
  },
)

const setFormSchemaInitialized = () => {
  if (!formSchemaInitialized.value) {
    formSchemaInitialized.value = true
  }
}

const { notify, removeNotification } = useNotifications()

let formUpdaterQueryLoadingTimeoutId: NodeJS.Timeout | null

const clearFormUpdaterQueryLoadingTimeout = () => {
  if (!formUpdaterQueryLoadingTimeoutId) return

  clearTimeout(formUpdaterQueryLoadingTimeoutId)
  formUpdaterQueryLoadingTimeoutId = null
}

const cleanupFormUpdaterAutosaveNotification = () => {
  removeNotification('form-updater-autosave')
  clearFormUpdaterQueryLoadingTimeout()
}

const handleFormUpdaterAutosaveNotification = () => {
  if (
    !formUpdaterVariables.value?.meta.additionalData?.taskbarId &&
    !formUpdaterVariables.value?.meta.additionalData?.applyTaskbarState
  )
    return

  // Clean up previous notification and timeout.
  cleanupFormUpdaterAutosaveNotification()

  const formUpdaterQueryLoading = formUpdaterQueryHandler.loading()

  watch(formUpdaterQueryLoading, (isLoading) => {
    if (!isLoading) {
      cleanupFormUpdaterAutosaveNotification()
      return
    }

    // Clear previous timeout.
    clearFormUpdaterQueryLoadingTimeout()

    formUpdaterQueryLoadingTimeoutId = setTimeout(() => {
      // Show info notification if the request takes longer than a second.
      notify({
        id: 'form-updater-autosave',
        message: __('Autosave in progress…'),
        type: NotificationTypes.Info,
        persistent: true,
      })

      // Show warning notification if the request takes longer than five seconds.
      formUpdaterQueryLoadingTimeoutId = setTimeout(() => {
        notify({
          id: 'form-updater-autosave',
          message: __('Autosaving is taking longer than expected…'),
          type: NotificationTypes.Warn,
          persistent: true,
        })
      }, 6000)
    }, 2000)
  })
}

const formUpdaterScope = effectScope()

onBeforeUnmount(() => {
  if (formUpdaterScope.active) formUpdaterScope.stop()
  cleanupFormUpdaterAutosaveNotification()
})

const initializeFormSchema = () => {
  buildStaticSchema()

  if (props.formUpdaterId) {
    formUpdaterVariables.value = markRaw({
      id: props.initialEntityObject?.id,
      formUpdaterId: props.formUpdaterId,
      data: localInitialValues,
      meta: {
        initial: true,
        additionalData: props.formUpdaterAdditionalParams,
        formId,
      },
      relationFields,
    })

    formUpdaterScope.run(() => {
      formUpdaterQueryHandler = new QueryHandler(
        useFormUpdaterQuery(formUpdaterVariables as Ref<FormUpdaterQueryVariables>, {
          context: {
            batch: {
              active: false,
            },
            websocket: {
              active: true,
            },
            skipSubscription: 'userCurrentTaskbarItemStateUpdates',
            skipSubscriptionAddCallback: (variables: FormUpdaterQueryVariables) => {
              return (
                !variables.meta.initial &&
                !variables.meta.reset &&
                !variables.meta.additionalData.applyTaskbarState
              )
            },
          },
          fetchPolicy: 'no-cache',
        }),
      )
    })

    handleFormUpdaterAutosaveNotification()

    formUpdaterQueryHandler.onResult((queryResult) => {
      // Execute the form handler function so that they can manipulate the form updater result.
      if (!formSchemaInitialized.value) {
        executeFormHandler(
          FormHandlerExecution.Initial,
          localInitialValues,
          undefined,
          queryResult?.data?.formUpdater,
        )
      }

      if (queryResult?.data?.formUpdater) {
        Object.assign(schemaData.flags, queryResult.data.formUpdater.flags)

        updateChangedFields(
          changeFields.value
            ? merge(queryResult.data.formUpdater.fields, changeFields.value)
            : queryResult.data.formUpdater.fields,
        )
      }

      setFormSchemaInitialized()
    })
  } else {
    executeFormHandler(FormHandlerExecution.Initial, localInitialValues)
    if (changeFields.value) updateChangedFields(changeFields.value)

    setFormSchemaInitialized()
  }
}

// TODO: maybe we should react on schema changes and rebuild the static schema with a new form-id and re-rendering of
// the complete form (= use the formId as the key for the whole form to trigger the re-rendering of the component...)
if (props.schema) {
  showInitialLoadingAnimation.value = true

  if (props.useObjectAttributes) {
    // TODO: rebuild schema, when object attributes
    // was changed from outside(not such important,
    // because we have currently the reload solution like in the desktop view).
    if (props.objectAttributeSkippedFields) {
      fixedAndSkippedFields.push(...props.objectAttributeSkippedFields)
    }

    const objectAttributeObjects: EnumObjectManagerObjects[] = []

    const addObjectAttributeToObjects = (object: EnumObjectManagerObjects) => {
      if (objectAttributeObjects.includes(object)) return

      objectAttributeObjects.push(object)
    }

    const detectObjectAttributeObjects = (schema: FormSchemaNode[] = props.schema) => {
      schema.forEach((item) => {
        if (typeof item === 'string') return

        if ('object' in item) {
          if ('name' in item && item.name && !item.type) {
            fixedAndSkippedFields.push(item.name)
          }

          addObjectAttributeToObjects(item.object)
        }

        if ('children' in item && Array.isArray(item.children)) {
          detectObjectAttributeObjects(item.children)
        }
      })
    }

    detectObjectAttributeObjects()

    // We need only to fetch object attributes, when there are used in the given schema.
    if (objectAttributeObjects.length > 0) {
      const { objectAttributesLoading } = useObjectAttributeLoadFormFields(objectAttributeObjects)

      const unwatchTriggerFormInitialize = watch(
        objectAttributesLoading,
        (loading) => {
          if (!loading) {
            nextTick(() => unwatchTriggerFormInitialize())
            initializeFormSchema()
          }
        },
        { immediate: true },
      )
    } else {
      initializeFormSchema()
    }
  } else {
    initializeFormSchema()
  }
}

const classMap = getFormClasses()

defineExpose({
  formNode,
  formInitialSettled,
  formId,
  values,
  flags: schemaDataFlags,
  updateChangedFields,
  updateSchemaDataField,
  getNodeByName,
  findNodeByName,
  resetForm,
  triggerFormUpdater,
})
</script>

<script lang="ts">
export default {
  inheritAttrs: false,
}
</script>

<template>
  <div v-if="debouncedShowInitialLoadingAnimation" class="flex items-center justify-center">
    <CommonIcon :class="classMap.loading" name="loading" animation="spin" />
  </div>
  <FormKit
    v-if="
      hasSchema &&
      ((formSchemaInitialized && Object.keys(schemaData.fields).length > 0) || $slots.default)
    "
    v-bind="$attrs"
    :id="id"
    type="form"
    novalidate
    :config="formConfig"
    :form-class="localClass"
    :actions="false"
    :incomplete-message="false"
    :plugins="localFormKitPlugins"
    :sections-schema="formKitSectionsSchema"
    :disabled="disabled"
    @node="setFormNode"
    @submit="onSubmit"
    @submit-raw="onSubmitRaw"
  >
    <FormKitMessages
      :node="formNode"
      :sections-schema="{
        messages: {
          $el: 'div',
        },
        message: {
          $el: undefined,
          $cmp: 'CommonAlert',
          props: {
            id: `$: '${id}-' + $message.key`,
            key: '$message.key',
            variant: {
              if: '$message.type == error || $message.type == validation',
              then: 'danger',
              else: '$message.type',
            },
          },
          children: '$fns.t($message.value)',
        },
      }"
    />

    <slot name="before-fields" />

    <slot
      name="default"
      :schema="staticSchema"
      :data="schemaData"
      :library="additionalComponentLibrary"
    >
      <div
        v-show="formKitInitialNodesSettled && !debouncedShowInitialLoadingAnimation"
        ref="form"
        :class="formClass"
      >
        <FormKitSchema
          :schema="staticSchema"
          :data="schemaData"
          :library="additionalComponentLibrary"
        />
      </div>
    </slot>
    <slot name="after-fields" />
  </FormKit>
</template>
