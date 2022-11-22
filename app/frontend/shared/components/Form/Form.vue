<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { isEqual, cloneDeep, merge } from 'lodash-es'
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
import { createMessage } from '@formkit/core'
import type { SetRequired } from 'type-fest'
import type { Stoppable } from '@vueuse/shared'
import { useTimeoutFn, watchOnce } from '@vueuse/shared'
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
} from '@shared/graphql/types'
import { QueryHandler } from '@shared/server/apollo/handler'
import { useObjectAttributeLoadFormFields } from '@shared/entities/object-attributes/composables/useObjectAttributeLoadFormFields'
import { useObjectAttributeFormFields } from '@shared/entities/object-attributes/composables/useObjectAttributeFormFields'
import testFlags from '@shared/utils/testFlags'
import { edgesToArray } from '@shared/utils/helpers'
import type { FormUpdaterTrigger } from '@shared/types/form'
import type { ObjectLike } from '@shared/types/utils'
import { getFirstFocusableElement } from '@shared/utils/getFocusableElements'
import { useFormUpdaterQuery } from './graphql/queries/formUpdater.api'
import {
  type FormData,
  type FormSchemaField,
  type FormSchemaLayout,
  type FormSchemaNode,
  type FormValues,
  type FormFieldValue,
  type ReactiveFormSchemData,
  FormValidationVisibility,
} from './types'
import FormLayout from './FormLayout.vue'
import FormGroup from './FormGroup.vue'

// TODO:
// - Maybe some default buttons inside the components with loading cycle on submit?
// (- Disabled form on submit? (i think it's the default of FormKit, but only when a promise will be returned from the submit handler))
// - Reset/Clear form handling?
// - Add usage of "clearErrors(true)"?

export interface Props {
  id?: string
  schema?: FormSchemaNode[]
  formUpdaterId?: EnumFormUpdaterId
  changeFields?: Record<string, Partial<FormSchemaField>>
  // Maybe in the future this is no longer needed, when FormKit supports group
  // without value grouping below group name (https://github.com/formkit/formkit/issues/461).
  multiStepFormGroups?: string[]
  formKitPlugins?: FormKitPlugin[]
  formKitSectionsSchema?: Record<
    string,
    Partial<FormKitSchemaNode> | FormKitSchemaCondition
  >
  class?: FormKitClasses | string | Record<string, boolean>

  // Can be used to define initial values on frontend side and fetched schema from the server.
  initialValues?: Partial<FormValues>
  initialEntityObject?: ObjectLike
  queryParams?: Record<string, unknown>
  validationVisibility?: FormValidationVisibility
  disabled?: boolean
  autofocus?: boolean

  // Some special properties for working with object attribute fields inside of a form schema.
  useObjectAttributes?: boolean
  objectAttributeSkippedFields?: string[]

  // WARNING
  // Don't forget that to submit a form with "Enter" key, you need to add a button with type="submit" inside of the form.
  // Or to have a button outside of form with "form" attribite with the same value as the form id.
  // Implement the submit in this way, because we need to react on async usage of the submit function.
  onSubmit?: (values: FormData) => Promise<void> | void
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
    return {}
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
let loadingAnimationTimeout: Stoppable

const stopLoadingAnimationTimeOut = () => {
  if (loadingAnimationTimeout) {
    loadingAnimationTimeout.stop()
  }
}

const startInitialLoadingAnimation = () => {
  stopLoadingAnimationTimeOut()

  loadingAnimationTimeout = useTimeoutFn(() => {
    showInitialLoadingAnimation.value = true
  }, 300)
}

const stopInitialLoadingAnimation = () => {
  stopLoadingAnimationTimeOut()

  loadingAnimationTimeout = useTimeoutFn(() => {
    showInitialLoadingAnimation.value = false
  }, 300)
}

const formKitInitialNodesSettled = ref(false)
const formNode: Ref<FormKitNode | undefined> = ref()
const formElement = ref<HTMLElement>()

const updaterChangedFields = new Set<string>()

const setFormNode = (node: FormKitNode) => {
  formNode.value = node

  // Save the initial entity object in the form node context, so that fields can use it.
  if (node.context && props.initialEntityObject) {
    node.context.initialEntityObject = props.initialEntityObject
  }

  node.settled.then(() => {
    stopInitialLoadingAnimation()
    formKitInitialNodesSettled.value = true

    // Reset directly after the initial request.
    updaterChangedFields.clear()

    const formName = node.context?.id || node.name
    testFlags.set(`${formName}.settled`)
    emit('settled')

    if (props.autofocus) {
      nextTick(() => {
        const firstInput = getFirstFocusableElement(formElement.value)

        firstInput?.focus()
        firstInput?.scrollIntoView({ block: 'nearest' })
      })
    }
  })

  emit('node', node)
}

const formNodeContext = computed(() => formNode.value?.context)

defineExpose({
  formNode,
})

// Build the flat value, when multi step form groups are used.
const getFlatValues = (values: FormValues, multiStepFormGroups: string[]) => {
  const flatValues = {
    ...values,
  }

  multiStepFormGroups.forEach((stepFormGroup) => {
    Object.assign(flatValues, flatValues[stepFormGroup])
    delete flatValues[stepFormGroup]
  })

  return flatValues
}

// Use the node context value, instead of the v-model, because of performance reason.
const values = computed<FormValues>(() => {
  if (!formNodeContext.value) {
    return {}
  }

  if (!props.multiStepFormGroups) return formNodeContext.value.value

  return getFlatValues(formNodeContext.value.value, props.multiStepFormGroups)
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

const onSubmit = (values: FormData): Promise<void> | void => {
  // Needs to be checked, because the 'onSubmit' function is not required.
  if (!props.onSubmit) return undefined

  const emitValues = {
    ...(props.multiStepFormGroups
      ? getFlatValues(values, props.multiStepFormGroups)
      : values),
    formId,
  }

  const submitResult = props.onSubmit(emitValues)

  // TODO: Maybe we need to handle the disabled state on submit on our own. In clarification with FormKit (https://github.com/formkit/formkit/issues/236).
  if (submitResult instanceof Promise) {
    return submitResult.catch((errors: UserError) => {
      if (errors instanceof UserError) {
        formNode.value?.setErrors(
          errors.generalErrors as string[],
          errors.getFieldErrorList(),
        )
      }
    })
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
})

const internalFieldCamelizeName: Record<string, string> = {}

const getInitialEntityObjectValue = (fieldName: string): FormFieldValue => {
  if (!props.initialEntityObject) return undefined

  let value: FormFieldValue
  if (relationFieldBelongsToObjectField[fieldName]) {
    const belongsToObject =
      props.initialEntityObject[relationFieldBelongsToObjectField[fieldName]]

    if (!belongsToObject) return undefined

    if ('edges' in belongsToObject) {
      value = edgesToArray(
        belongsToObject as { edges?: { node: { internalId: number } }[] },
      ).map((item) => item.internalId)
    } else {
      value = belongsToObject?.internalId
    }
  }

  if (!value) {
    value =
      props.initialEntityObject[
        internalFieldCamelizeName[fieldName] || fieldName
      ]
  }

  return value
}

const localInitialValues: FormValues = props.initialValues || {}

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

const updateSchemaDataField = (
  field: FormSchemaField | SetRequired<Partial<FormSchemaField>, 'name'>,
) => {
  const {
    show,
    updateFields,
    relation,
    props: specificProps,
    ...fieldProps
  } = field
  const showField = show ?? true

  // Special handling for the disabled prop, so that the form can handle also
  // the disable state from outside.
  if ('disabled' in fieldProps && !fieldProps.disabled) {
    fieldProps.disabled = undefined
  }

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
      localInitialValues[field.name] ??
      getInitialEntityObjectValue(field.name) ??
      combinedFieldProps.value

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
      formNode.value?.at(fieldName)?.input(value, false)
    }
  })

  nextTick(() => {
    updaterChangedFields.clear()
    formNode.value?.store.remove('formUpdaterProcessing')
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

    if (!updaterChangedFields.has(node.name)) {
      handlesFormUpdater(
        inputNode.props.formUpdaterTrigger,
        node.name,
        newValue,
        oldValue,
      )
    }

    emit('changed', node.name, newValue, oldValue)

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
    return {
      $cmp: 'FormKit',
      if: `$fields.${field.name}.show`,
      bind: `$fields.${field.name}.props`,
      props: {
        type: field.type,
        key: field.name,
        id: field.id || `form_field_${field.name}`,
        formId,
        plugins: [changedInputValueHandling],
        triggerFormUpdater: !!props.formUpdaterId,
      },
    }
  }

  const getLayoutType = (
    layoutNode: FormSchemaLayout,
  ): FormKitSchemaDOMNode | FormKitSchemaComponent => {
    // TODO: this both nodes could maybe be improved, to support also conditions?
    if ('component' in layoutNode) {
      return {
        $cmp: layoutNode.component,
        props: layoutNode.props,
      }
    }

    return {
      $el: layoutNode.element,
      attrs: layoutNode.attrs,
    }
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
        props: {
          type: node.type,
          name: node.name,
          key: node.name,
        },
      }
    }

    if ('object' in node && getFormFieldSchema && getFormFieldsFromScreen) {
      if ('name' in node && node.name && !node.type) {
        const resolvedField = getFormFieldSchema(
          node.name,
          node.object,
          node.screen,
        )

        if (!resolvedField) return null

        // Remove no longer needed screen value.
        delete node.screen

        node = {
          ...resolvedField,
          ...node,
        }
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
  watch(() => props.changeFields, updateChangedFields, {
    deep: true,
  })
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

    formUpdaterQueryHandler.watchOnResult((queryResult) => {
      if (queryResult?.formUpdater) {
        updateChangedFields(
          props.changeFields
            ? merge(queryResult.formUpdater, props.changeFields)
            : queryResult.formUpdater,
        )
      }

      if (!formSchemaInitialized.value) formSchemaInitialized.value = true
    })
  } else {
    if (props.changeFields) updateChangedFields(props.changeFields)

    formSchemaInitialized.value = true
  }
}

// TODO: maybe we should react on schema changes and rebuild the static schema with a new form-id and re-rendering of
// the complete form (= use the formId as the key for the whole form to trigger the re-rendering of the component...)
// ...

if (props.schema) {
  if (props.useObjectAttributes) {
    startInitialLoadingAnimation()
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

      watch(
        objectAttributesLoading,
        (loading) => {
          if (!loading) initializeFormSchema()
        },
        { immediate: true },
      )
    } else {
      initializeFormSchema()
    }
  } else {
    startInitialLoadingAnimation()
    initializeFormSchema()
  }
}
</script>

<template>
  <div
    v-if="showInitialLoadingAnimation"
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
    :id="id"
    type="form"
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
        v-show="formKitInitialNodesSettled && !showInitialLoadingAnimation"
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
