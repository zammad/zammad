<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { isEqual, cloneDeep, merge, isEmpty } from 'lodash-es'
import type { ConcreteComponent, Ref } from 'vue'
import {
  computed,
  ref,
  nextTick,
  shallowRef,
  reactive,
  toRef,
  watch,
  markRaw,
  useSlots,
} from 'vue'
import { FormKit, FormKitSchema } from '@formkit/vue'
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
import { createMessage, getNode, reset } from '@formkit/core'
import type { Except, SetRequired } from 'type-fest'
import { refDebounced, watchOnce } from '@vueuse/shared'
import getUuid from '@shared/utils/getUuid'
import log from '@shared/utils/log'
import { camelize } from '@shared/utils/formatter'
import UserError from '@shared/errors/UserError'
import type {
  EnumObjectManagerObjects,
  EnumFormUpdaterId,
  FormUpdaterRelationField,
  FormUpdaterQuery,
  FormUpdaterQueryVariables,
  ObjectAttributeValue,
} from '@shared/graphql/types'
import { QueryHandler } from '@shared/server/apollo/handler'
import { useObjectAttributeLoadFormFields } from '@shared/entities/object-attributes/composables/useObjectAttributeLoadFormFields'
import { useObjectAttributeFormFields } from '@shared/entities/object-attributes/composables/useObjectAttributeFormFields'
import testFlags from '@shared/utils/testFlags'
import { edgesToArray } from '@shared/utils/helpers'
import type { FormUpdaterTrigger } from '@shared/types/form'
import type { EntityObject } from '@shared/types/entity'
import { getFirstFocusableElement } from '@shared/utils/getFocusableElements'
import { parseGraphqlId } from '@shared/graphql/utils'
import { useFormUpdaterQuery } from './graphql/queries/formUpdater.api'
import { FormHandlerExecution, FormValidationVisibility } from './types'
import type {
  ChangedField,
  FormData,
  FormFieldAdditionalProps,
  FormFieldValue,
  FormHandler,
  FormHandlerFunction,
  FormSchemaField,
  FormSchemaLayout,
  FormSchemaNode,
  FormValues,
  ReactiveFormSchemData,
} from './types'
import FormLayout from './FormLayout.vue'
import FormGroup from './FormGroup.vue'

export interface Props {
  id?: string
  schema?: FormSchemaNode[]
  formUpdaterId?: EnumFormUpdaterId
  handlers?: FormHandler[]
  changeFields?: Record<string, Partial<FormSchemaField>>
  // Maybe in the future this is no longer needed, when FormKit supports group
  // without value grouping below group name (https://github.com/formkit/formkit/issues/461).
  flattenFormGroups?: string[]
  schemaData?: Except<ReactiveFormSchemData, 'fields'>
  formKitPlugins?: FormKitPlugin[]
  formKitSectionsSchema?: Record<
    string,
    Partial<FormKitSchemaNode> | FormKitSchemaCondition
  >
  class?: FormKitClasses | string | Record<string, boolean>

  // Can be used to define initial values on frontend side and fetched schema from the server.
  initialValues?: Partial<FormValues>
  initialEntityObject?: EntityObject
  queryParams?: Record<string, unknown>
  validationVisibility?: FormValidationVisibility
  disabled?: boolean
  autofocus?: boolean

  // Some special properties for working with object attribute fields inside of a form schema.
  useObjectAttributes?: boolean
  objectAttributeSkippedFields?: string[]

  // Implement the submit in this way, because we need to react on async usage of the submit function.
  // Don't forget that to submit a form with "Enter" key, you need to add a button with type="submit" inside of the form.
  // Or to have a button outside of form with "form" attribite with the same value as the form id.
  // After this method is called, form resets its values and state. If you need to call something afterwards,
  // like make route navigation, you can return a function from the submit handler, which will be called after the form reset.
  onSubmit?: (
    values: FormData,
  ) => Promise<void | (() => void)> | void | (() => void)
}

// Zammad currently expects formIds to be BigInts. Maybe convert to UUIDs later.
// const formId = `form-${getUuid()}`

// This is the formId generation logic from the legacy desktop app.
let formId = new Date().getTime() + Math.floor(Math.random() * 99999).toString()
formId = formId.substr(formId.length - 9, 9)

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

const slots = useSlots()

const hasSchema = computed(
  () => Boolean(slots.default) || Boolean(props.schema),
)
const formSchemaInitialized = ref(false)

if (!hasSchema.value) {
  log.error(
    'No schema defined. Please use the schema prop or the default slot for the schema.',
  )
}

// Rename prop 'class' for usage in the template, because of reserved word
const localClass = toRef(props, 'class')

const emit = defineEmits<{
  (
    e: 'changed',
    fieldName: string,
    newValue: FormFieldValue,
    oldValue: FormFieldValue,
  ): void
  (e: 'node', node: FormKitNode): void
  (e: 'settled'): void
}>()

const showInitialLoadingAnimation = ref(false)
const debouncedShowInitialLoadingAnimation = refDebounced(
  showInitialLoadingAnimation,
  300,
)

const formKitInitialNodesSettled = ref(false)
const formNode: Ref<FormKitNode | undefined> = ref()
const formElement = ref<HTMLElement>()

const changeFields = toRef(props, 'changeFields')

const updaterChangedFields = new Set<string>()

const autofocusFirstInput = () => {
  nextTick(() => {
    const firstInput = getFirstFocusableElement(formElement.value)

    firstInput?.focus()
    firstInput?.scrollIntoView({ block: 'nearest' })
  })
}

const setFormNode = (node: FormKitNode) => {
  formNode.value = node

  // Save the initial entity object in the form node context, so that fields can use it.
  if (node.context && props.initialEntityObject) {
    node.context.initialEntityObject = props.initialEntityObject
  }

  node.settled.then(() => {
    showInitialLoadingAnimation.value = false
    formKitInitialNodesSettled.value = true

    // Reset directly after the initial request.
    updaterChangedFields.clear()

    const formName = node.context?.id || node.name
    testFlags.set(`${formName}.settled`)
    emit('settled')

    if (props.autofocus) autofocusFirstInput()
  })

  node.on('autofocus', autofocusFirstInput)

  emit('node', node)
}

const formNodeContext = computed(() => formNode.value?.context)

// Build the flat value when its requested for specific form groups.
const getFlatValues = (values: FormValues, formGroups: string[]) => {
  const flatValues = {
    ...values,
  }

  formGroups.forEach((formGroup) => {
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

  if (!props.flattenFormGroups) return formNodeContext.value.value

  return getFlatValues(formNodeContext.value.value, props.flattenFormGroups)
})

const relationFields: FormUpdaterRelationField[] = []
const relationFieldBelongsToObjectField: Record<string, string> = {}

const formUpdaterProcessing = computed(
  () => formNode.value?.context?.state.formUpdaterProcessing || false,
)

let delayedSubmit = false
const onSubmitRaw = () => {
  if (formUpdaterProcessing.value) {
    delayedSubmit = true
  }
}

const onSubmit = (values: FormData) => {
  // Needs to be checked, because the 'onSubmit' function is not required.
  if (!props.onSubmit) return undefined

  const flatValues = props.flattenFormGroups
    ? getFlatValues(values, props.flattenFormGroups)
    : values
  const emitValues = {
    ...flatValues,
    formId,
  }

  const submitResult = props.onSubmit(emitValues)

  if (submitResult instanceof Promise) {
    return submitResult
      .then((afterReset) => {
        // it's possible to destroy Form before this is called
        if (!formNode.value) return
        reset(formNode.value, values)
        if (typeof afterReset === 'function') afterReset()
      })
      .catch((errors: UserError) => {
        if (errors instanceof UserError) {
          formNode.value?.setErrors(
            // TODO: we need to check/style the general error output when we want to show it related to the form
            errors.generalErrors as string[],
            errors.getFieldErrorList(),
          )
        }
      })
  }

  if (formNode.value) {
    reset(formNode.value, values)
  }

  if (typeof submitResult === 'function') {
    submitResult()
  }

  return submitResult
}

let formUpdaterQueryHandler: QueryHandler<
  FormUpdaterQuery,
  FormUpdaterQueryVariables
>

const delayedSubmitPlugin = (node: FormKitNode) => {
  node.on('message-removed', async ({ payload }) => {
    if (payload.key === 'formUpdaterProcessing' && delayedSubmit) {
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
  return [delayedSubmitPlugin, ...(props.formKitPlugins || [])]
})

const formConfig = computed(() => {
  return {
    validationVisibility: props.validationVisibility,
  }
})

// Define the additional component library for the used components which are not form fields.
// Because of a typescript error, we need to cased the type: https://github.com/formkit/formkit/issues/274
const additionalComponentLibrary = {
  FormLayout: markRaw(FormLayout) as unknown as ConcreteComponent,
  FormGroup: markRaw(FormGroup) as unknown as ConcreteComponent,
}

// Define the static schema, which will be filled with the real fields from the `schemaData`.
const staticSchema = ref<FormKitSchemaNode[]>([])

const fixedAndSkippedFields: string[] = []

const schemaData = reactive<ReactiveFormSchemData>({
  fields: {},
  values,
  ...props.schemaData,
})

const internalFieldCamelizeName: Record<string, string> = {}

const getInternalId = (item?: { id?: string; internalId?: number }) => {
  if (!item) return undefined
  if (item.internalId) return item.internalId
  if (!item.id) return undefined
  return parseGraphqlId(item.id).id
}

let initialEntityObjectAttributeMap: Record<string, FormFieldValue> = {}
const setInitialEntityObjectAttributeMap = (
  initialEntityObject = props.initialEntityObject,
) => {
  if (isEmpty(initialEntityObject)) return

  const { objectAttributeValues } = initialEntityObject

  if (!objectAttributeValues) return

  // Reduce object attribute values to flat structure
  initialEntityObjectAttributeMap =
    objectAttributeValues.reduce((acc: Record<string, FormFieldValue>, cur) => {
      const { attribute } = cur

      if (!attribute || !attribute.name) return acc

      acc[attribute.name] = cur.value
      return acc
    }, {}) || {}
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
    const belongsToObject =
      initialEntityObject[relationFieldBelongsToObjectField[fieldName]]

    if (!belongsToObject) return undefined

    if ('edges' in belongsToObject) {
      value = edgesToArray(
        belongsToObject as { edges?: { node: { internalId: number } }[] },
      ).map((item) => getInternalId(item))
    } else {
      value = getInternalId(belongsToObject)
    }
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
  values: FormValues,
  object?: EntityObject,
  groupNode?: FormKitNode,
  resetDirty = true,
) => {
  const resetValues: FormValues = {}
  const dirtyNodes: FormKitNode[] = []

  const setResetFormValue = (
    name: string,
    value: FormFieldValue,
    parentName?: string,
  ) => {
    if (parentName) {
      resetValues[parentName] ||= {}
      ;(resetValues[parentName] as Record<string, FormFieldValue>)[name] = value
      return
    }

    resetValues[name] = value
  }

  Object.entries(schemaData.fields).forEach(([field, { props }]) => {
    const formElement = getNode(props.id || props.name)

    let parentName = ''
    if (formElement?.parent && formElement?.parent.name !== rootNode.name) {
      parentName = formElement.parent.name
    }

    // Do not use the parentName, when we are in group node reset context.
    const groupName = groupNode?.name
    if (groupName) {
      if (parentName !== groupName) return
      parentName = ''
    }

    if (!resetDirty && formElement?.context?.state.dirty) {
      dirtyNodes.push(formElement)
      setResetFormValue(field, formElement._value as FormFieldValue, parentName)
      return
    }

    if (field in values) {
      setResetFormValue(field, values[field], parentName)
      return
    }
    if (parentName && parentName in values) {
      const value = (values[parentName] as Record<string, FormFieldValue>)[
        field
      ]

      setResetFormValue(field, value, parentName)
      return
    }

    const objectValue = getInitialEntityObjectValue(field, object)
    if (objectValue !== undefined) {
      setResetFormValue(field, objectValue, parentName)
    }
  })

  return {
    dirtyNodes,
    resetValues,
  }
}

const resetForm = (
  values: FormValues = {},
  object: EntityObject | undefined = undefined,
  { resetDirty = true }: { resetDirty?: boolean } = {},
  groupNode: FormKitNode | undefined = undefined,
) => {
  if (!formNode.value) return

  const rootNode = formNode.value

  if (object) setInitialEntityObjectAttributeMap(object)

  const { dirtyNodes, resetValues } = getResetFormValues(
    rootNode,
    values,
    object,
    groupNode,
    resetDirty,
  )

  reset(
    groupNode || rootNode,
    Object.keys(resetValues).length ? resetValues : undefined,
  )

  // keep dirty nodes as dirty
  // TODO: check if we need to skip the formUpdater???
  dirtyNodes.forEach((node) => {
    node.input(node._value, false)
  })
}

defineExpose({
  formNode,
  resetForm,
})

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

const updateSchemaLink = (
  specificProps: FormFieldAdditionalProps,
  fieldName: string,
) => {
  // native fields don't have link attribute, and we don't have a way to get rendered link from graphql
  const values = (props.initialEntityObject?.objectAttributeValues ||
    []) as ObjectAttributeValue[]
  const attribute = values.find(({ attribute }) => attribute.name === fieldName)
  if (attribute?.renderedLink) {
    specificProps.link = attribute.renderedLink
  }
}

const updateSchemaDataField = (
  field: FormSchemaField | SetRequired<Partial<FormSchemaField>, 'name'>,
) => {
  const {
    show,
    updateFields,
    relation,
    props: specificProps = {},
    ...fieldProps
  } = field
  const showField = show ?? schemaData.fields[field.name]?.show ?? true

  // Not needed in this context.
  delete fieldProps.if

  // Special handling for the disabled prop, so that the form can handle also
  // the disable state from outside.
  if ('disabled' in fieldProps && !fieldProps.disabled) {
    fieldProps.disabled = undefined
  }

  updateSchemaLink(fieldProps, field.name)

  if (schemaData.fields[field.name]) {
    schemaData.fields[field.name] = {
      show: showField,
      updateFields: updateFields || false,
      props: Object.assign(
        schemaData.fields[field.name].props,
        fieldProps,
        specificProps,
      ),
    }
  } else {
    initializeFieldRelation(
      field.name,
      relation,
      specificProps?.belongsToObjectField,
    )

    setInternalField(field.name, Boolean(fieldProps.internal))

    const combinedFieldProps = Object.assign(fieldProps, specificProps)

    // Select the correct initial value (at this time localInitialValues has not already the information
    // from the initial entity object, so we need to check it manually).
    combinedFieldProps.value =
      field.name in localInitialValues
        ? localInitialValues[field.name]
        : getInitialEntityObjectValue(field.name) ?? combinedFieldProps.value

    // Save current initial value for later usage, when not already exists.
    if (!(field.name in localInitialValues))
      localInitialValues[field.name] = combinedFieldProps.value

    schemaData.fields[field.name] = {
      show: showField,
      updateFields: updateFields || false,
      props: combinedFieldProps,
    }
  }
}

const updateChangedFields = (
  changedFields: Record<string, Partial<FormSchemaField>>,
) => {
  Object.keys(changedFields).forEach(async (fieldName) => {
    if (!schemaData.fields[fieldName]) return

    const { value, ...changedFieldProps } = changedFields[fieldName]

    const field: SetRequired<Partial<FormSchemaField>, 'name'> = {
      ...changedFieldProps,
      name: fieldName,
    }

    if (
      value !== undefined &&
      (!formKitInitialNodesSettled.value ||
        (!schemaData.fields[fieldName].show && changedFieldProps.show))
    ) {
      field.value = value
    }

    // When a field will be visible with the update call, we need to wait before on a settled form, before we
    // continue (so that we have all values present inside the form).
    // This situtation can happen, when the form is used very fast.
    if (
      formKitInitialNodesSettled.value &&
      !schemaData.fields[fieldName].show &&
      changedFieldProps.show &&
      !formNode.value?.isSettled
    ) {
      await formNode.value?.settled
    }

    updaterChangedFields.add(fieldName)
    updateSchemaDataField(field)

    if (!formKitInitialNodesSettled.value) return

    if (
      !('value' in field) &&
      value !== undefined &&
      value !== values.value[fieldName]
    ) {
      updaterChangedFields.add(fieldName)
      getNode(fieldName)?.input(value, false)
    }
  })

  nextTick(() => {
    updaterChangedFields.clear()
    formNode.value?.store.remove('formUpdaterProcessing')
  })
}

const formHandlerExecution: Record<
  FormHandlerExecution,
  FormHandlerFunction[]
> = {
  [FormHandlerExecution.Initial]: [],
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
) => {
  if (formHandlerExecution[execution].length === 0) return

  formHandlerExecution[execution].forEach((handler) => {
    handler(
      execution,
      formNode.value,
      currentValues,
      changeFields,
      updateSchemaDataField,
      schemaData,
      changedField,
      props.initialEntityObject,
    )
  })
}

const formUpdaterVariables = shallowRef<FormUpdaterQueryVariables>()
let nextFormUpdaterVariables: Maybe<FormUpdaterQueryVariables>
const executeFormUpdaterRefetch = () => {
  if (!nextFormUpdaterVariables) return

  formUpdaterVariables.value = nextFormUpdaterVariables

  // Reset the next variables so that it's not triggered a second time.
  nextFormUpdaterVariables = null
}

const handlesFormUpdater = (
  trigger: FormUpdaterTrigger,
  fieldName: string,
  newValue: FormFieldValue,
  oldValue: FormFieldValue,
) => {
  if (!props.formUpdaterId || !formUpdaterQueryHandler) return

  // We mark this as raw, because we want no deep reactivity on the form updater query variables.
  nextFormUpdaterVariables = markRaw({
    id: props.initialEntityObject?.id,
    formUpdaterId: props.formUpdaterId,
    data: {
      ...values.value,
      [fieldName]: newValue,
    },
    meta: {
      // We need a unique requestId, so that the query will always be executed on changes, also when the variables
      // are the same until the last request, because it could be that core workflow is setting a value back.
      requestId: getUuid(),
      formId,
      changedField: {
        name: fieldName,
        newValue,
        oldValue,
      },
    },
    relationFields,
  })

  formNode.value?.store.set(
    createMessage({
      blocking: true,
      key: 'formUpdaterProcessing',
      value: true,
      visible: false,
    }),
  )

  if (trigger !== 'blur') executeFormUpdaterRefetch()
}

const previousValues = new WeakMap<FormKitNode, FormFieldValue>()
const changedInputValueHandling = (inputNode: FormKitNode) => {
  inputNode.on('commit', ({ payload: newValue, origin: node }) => {
    const oldValue = previousValues.get(node)
    if (isEqual(newValue, oldValue)) return

    if (!formKitInitialNodesSettled.value) {
      previousValues.set(node, cloneDeep(newValue))
      return
    }
    if (
      inputNode.props.triggerFormUpdater &&
      !updaterChangedFields.has(node.name)
    ) {
      handlesFormUpdater(
        inputNode.props.formUpdaterTrigger,
        node.name,
        newValue,
        oldValue,
      )
    }
    emit('changed', node.name, newValue, oldValue)
    executeFormHandler(FormHandlerExecution.FieldChange, values.value, {
      name: node.name,
      newValue,
      oldValue,
    })
    previousValues.set(node, cloneDeep(newValue))
    updaterChangedFields.delete(node.name)
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
  const { getFormFieldSchema, getFormFieldsFromScreen } =
    useObjectAttributeFormFields(fixedAndSkippedFields)

  const buildFormKitField = (
    field: FormSchemaField,
  ): FormKitSchemaComponent => {
    const fieldId = field.id || field.name

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
        plugins: [changedInputValueHandling],
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
        props: layoutNode.props,
      }
    } else {
      layoutField = {
        $el: layoutNode.element,
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
      return {
        $cmp: 'FormKit',
        ...(node.if && { if: node.if }),
        props: {
          type: node.type,
          name: node.name,
          id: node.name,
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
      updateChangedFields(newValue)
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

const initializeFormSchema = () => {
  buildStaticSchema()

  if (props.formUpdaterId) {
    formUpdaterVariables.value = markRaw({
      id: props.initialEntityObject?.id,
      formUpdaterId: props.formUpdaterId,
      data: localInitialValues,
      meta: {
        initial: true,
        formId,
      },
      relationFields,
    })

    formUpdaterQueryHandler = new QueryHandler(
      useFormUpdaterQuery(
        formUpdaterVariables as Ref<FormUpdaterQueryVariables>,
        {
          fetchPolicy: 'no-cache',
        },
      ),
    )

    formUpdaterQueryHandler.onResult((queryResult) => {
      // Execute the form handler function so that they can manipulate the form updater result.
      if (!formSchemaInitialized.value) {
        executeFormHandler(FormHandlerExecution.Initial, localInitialValues)
      }

      if (queryResult?.data.formUpdater) {
        updateChangedFields(
          changeFields.value
            ? merge(queryResult.data.formUpdater, changeFields.value)
            : queryResult.data.formUpdater,
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

    const detectObjectAttributeObjects = (
      schema: FormSchemaNode[] = props.schema,
    ) => {
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
      const { objectAttributesLoading } = useObjectAttributeLoadFormFields(
        objectAttributeObjects,
      )

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
</script>

<script lang="ts">
export default {
  inheritAttrs: false,
}
</script>

<template>
  <div
    v-if="debouncedShowInitialLoadingAnimation"
    class="flex items-center justify-center"
  >
    <CommonIcon name="mobile-loading" animation="spin" />
  </div>
  <FormKit
    v-if="
      hasSchema &&
      ((formSchemaInitialized && Object.keys(schemaData.fields).length > 0) ||
        $slots.default)
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
    <slot name="before-fields" />
    <slot
      name="default"
      :schema="staticSchema"
      :data="schemaData"
      :library="additionalComponentLibrary"
    >
      <div
        v-show="
          formKitInitialNodesSettled && !debouncedShowInitialLoadingAnimation
        "
        ref="formElement"
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
