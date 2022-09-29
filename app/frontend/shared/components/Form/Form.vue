<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { ConcreteComponent, Ref } from 'vue'
import {
  computed,
  ref,
  reactive,
  toRef,
  watch,
  markRaw,
  nextTick,
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
} from '@formkit/core'
import { useTimeoutFn } from '@vueuse/shared'
import log from '@shared/utils/log'
import UserError from '@shared/errors/UserError'
import type {
  EnumObjectManagerObjects,
  EnumFormUpdaterId,
  FormUpdaterRelationField,
} from '@shared/graphql/types'
import { QueryHandler } from '@shared/server/apollo/handler'
import { useObjectAttributeLoadFormFields } from '@shared/entities/object-attributes/composables/useObjectAttributeLoadFormFields'
import { useObjectAttributeFormFields } from '@shared/entities/object-attributes/composables/useObjectAttributeFormFields'
import { useFormUpdaterQuery } from './graphql/queries/formUpdater.api'
import {
  type FormData,
  type FormSchemaField,
  type FormSchemaLayout,
  type FormSchemaNode,
  type FormValues,
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
  schema?: FormSchemaNode[]
  formUpdaterId?: EnumFormUpdaterId
  changeFields?: Record<string, FormSchemaField>
  formKitPlugins?: FormKitPlugin[]
  formKitSectionsSchema?: Record<
    string,
    Partial<FormKitSchemaNode> | FormKitSchemaCondition
  >
  class?: FormKitClasses | string | Record<string, boolean>

  // Can be used to define initial values on frontend side and fetched schema from the server.
  initialValues?: Partial<FormValues>
  queryParams?: Record<string, unknown>
  validationVisibility?: FormValidationVisibility
  disabled?: boolean

  // Some special properties for working with object attribute fields inside of a form schema.
  useObjectAttributes?: boolean
  objectAttributeSkippedFields?: string[]

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
  disabled: false,
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
  (e: 'changed', newValue: unknown, fieldName: string): void
  (e: 'node', node: FormKitNode): void
}>()

const formNode: Ref<FormKitNode | undefined> = ref()
const setFormNode = (node: FormKitNode) => {
  formNode.value = node

  emit('node', node)
}

const formNodeContext = computed(() => formNode.value?.context)

defineExpose({
  formNode,
})

// Use the node context value, instead of the v-model, because of performance reason.
const values = computed<FormValues>(() => {
  if (!formNodeContext.value) {
    return {}
  }
  return formNodeContext.value.value
})

const relationFields: FormUpdaterRelationField[] = []

const updateSchemaProcessing = ref(false)

const onSubmit = (values: FormData): Promise<void> | void => {
  // Needs to be checked, because the 'onSubmit' function is not required.
  if (!props.onSubmit) return undefined

  const emitValues = {
    ...values,
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

const coreWorkflowActive = ref(false)
const formUpdaterChanges = ref<Record<string, FormSchemaField>>({})

const changedValuePlugin = (node: FormKitNode) => {
  node.on('created', () => {
    node.on('input', ({ payload: value, origin: node }) => {
      // TODO: We need to ignore the initial events
      // TODO: trigger update form check (e.g. core workflow)
      // Or maybe also some "update"-flag on field level?
      if (coreWorkflowActive.value) {
        updateSchemaProcessing.value = true
        setTimeout(() => {
          // TODO: ... do some needed stuff
          formUpdaterChanges.value = {}
          updateSchemaProcessing.value = false
        }, 2000)
      }

      emit('changed', value, node.name)
    })
  })
}

const localFormKitPlugins = computed(() => {
  return [changedValuePlugin, ...(props.formKitPlugins || [])]
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

const updateSchemaDataField = (field: FormSchemaField) => {
  const { show, updateFields, props: specificProps, ...fieldProps } = field
  const showField = show ?? true

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
    schemaData.fields[field.name] = {
      show: showField,
      updateFields: updateFields || false,
      props: Object.assign(fieldProps, specificProps),
    }
  }
}

const buildStaticSchema = () => {
  const { getFormFieldSchema, getFormFieldsFromScreen } =
    useObjectAttributeFormFields(fixedAndSkippedFields)

  const buildFormKitField = (
    field: FormSchemaField,
  ): FormKitSchemaComponent => {
    if (field.relation) {
      relationFields.push({
        name: field.name,
        relation: field.relation,
        // TODO: Filter?
      })

      delete field.relation
    }

    return {
      $cmp: 'FormKit',
      if: `$fields.${field.name}.show`,
      bind: `$fields.${field.name}.props`,
      props: {
        type: field.type,
        key: field.name,
        id: field.id,
        formId,
        value: props.initialValues?.[field.name] ?? field.value,
      },
    }
  }

  const getLayoutType = (
    layoutNode: FormSchemaLayout,
  ): FormKitSchemaDOMNode | FormKitSchemaComponent => {
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
        const resolvedField = getFormFieldSchema(node.name, node.object)

        if (!resolvedField) return null

        node = {
          ...resolvedField,
          ...node,
        }
      } else if ('screen' in node) {
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

const localChangeFields = computed(() => {
  if (props.formUpdaterId) return formUpdaterChanges.value

  return props.changeFields
})

watch(
  localChangeFields,
  (newChangeFields) => {
    Object.keys(newChangeFields).forEach((fieldName) => {
      const field = {
        ...newChangeFields[fieldName],
        name: fieldName,
      }

      updateSchemaDataField(field)

      nextTick(() => {
        if (field.value !== values.value[fieldName]) {
          formNode.value?.at(fieldName)?.input(field.value)
        }
      })
    })
  },
  { deep: true },
)

const localDisabled = computed(() => {
  if (props.disabled) return props.disabled

  return updateSchemaProcessing.value
})

const showInitialLoadingAnimation = ref(false)
const {
  start: startLoadingAnimationTimeout,
  stop: stopLoadingAnimationTimeout,
} = useTimeoutFn(
  () => {
    showInitialLoadingAnimation.value = !showInitialLoadingAnimation.value
  },
  300,
  { immediate: false },
)

const toggleInitialLoadingAnimation = () => {
  stopLoadingAnimationTimeout()
  startLoadingAnimationTimeout()
}

const initializeFormSchema = () => {
  buildStaticSchema()

  if (props.formUpdaterId) {
    toggleInitialLoadingAnimation()
    new QueryHandler(
      useFormUpdaterQuery({
        formUpdaterId: props.formUpdaterId,
        data: {},
        meta: { formId },
        relationFields,
      }),
    ).watchOnResult((queryResult) => {
      if (queryResult?.formUpdater) {
        formUpdaterChanges.value = queryResult.formUpdater
        formSchemaInitialized.value = true
        toggleInitialLoadingAnimation()
      }
    })
  } else {
    formSchemaInitialized.value = true
  }
}

// TODO: maybe we should react on schema changes and rebuild the static schema with a new form-id and re-rendering of
// the complete form (= use the formId as the key for the whole form to trigger the re-rendering of the component...)
// ...

if (props.schema) {
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
    initializeFormSchema()
  }
}
</script>

<template>
  <FormKit
    v-if="
      hasSchema &&
      ((formSchemaInitialized && Object.keys(schemaData.fields).length > 0) ||
        $slots.default)
    "
    type="form"
    :config="formConfig"
    :form-class="localClass"
    :actions="false"
    :incomplete-message="false"
    :plugins="localFormKitPlugins"
    :sections-schema="formKitSectionsSchema"
    :disabled="localDisabled"
    @node="setFormNode"
    @submit="onSubmit"
  >
    <slot name="before-fields" />
    <slot
      name="default"
      :schema="staticSchema"
      :data="schemaData"
      :library="additionalComponentLibrary"
    >
      <FormKitSchema
        :schema="staticSchema"
        :data="schemaData"
        :library="additionalComponentLibrary"
      />
    </slot>
    <slot name="after-fields" />
  </FormKit>
  <div
    v-else-if="showInitialLoadingAnimation"
    class="flex items-center justify-center"
  >
    <CommonIcon name="loader" animation="spin" />
  </div>
</template>
