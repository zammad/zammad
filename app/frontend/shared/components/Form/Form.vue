<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { ConcreteComponent, Ref } from 'vue'
import { computed, ref, reactive, toRef, watch, markRaw, nextTick } from 'vue'
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
import UserError from '@shared/errors/UserError'
import type { EnumFormSchemaId } from '@shared/graphql/types'
import { QueryHandler } from '@shared/server/apollo/handler'
import { useFormSchemaQuery } from './graphql/queries/formSchema.api'
import type { FormSchemaGroupOrList } from './types'
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
  formSchemaId?: EnumFormSchemaId
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
})

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
const coreWorkflowChanges = ref<Record<string, FormSchemaField>>({})

const changedValuePlugin = (node: FormKitNode) => {
  node.on('input', ({ payload: value, origin: node }) => {
    // TODO: trigger update form check (e.g. core workflow)
    // Or maybe also some "update"-flag on field level?
    if (coreWorkflowActive.value) {
      updateSchemaProcessing.value = true
      setTimeout(() => {
        // TODO: ... do some needed stuff
        coreWorkflowChanges.value = {}
        updateSchemaProcessing.value = false
      }, 2000)
    }

    emit('changed', value, node.name)
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
const staticSchema: FormKitSchemaNode[] = []

const schemaData = reactive<ReactiveFormSchemData>({
  fields: {},
})

const updateSchemaDataField = (field: FormSchemaField) => {
  const { show, props: specificProps, ...fieldProps } = field
  const showField = show ?? true

  if (schemaData.fields[field.name]) {
    schemaData.fields[field.name] = {
      show: showField,
      props: Object.assign(
        schemaData.fields[field.name].props,
        fieldProps,
        specificProps,
      ),
    }
  } else {
    schemaData.fields[field.name] = {
      show: showField,
      props: Object.assign(fieldProps, specificProps),
    }
  }
}

const buildStaticSchema = (schema: FormSchemaNode[]) => {
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
        id: field.id,
        formId,
        value: props.initialValues?.[field.name] ?? field.value,
      },
    }
  }

  const getLayoutType = (
    layoutItem: FormSchemaLayout,
  ): FormKitSchemaDOMNode | FormKitSchemaComponent => {
    if ('component' in layoutItem) {
      return {
        $cmp: layoutItem.component,
        props: layoutItem.props,
      }
    }

    return {
      $el: layoutItem.element,
      attrs: layoutItem.attrs,
    }
  }

  schema.forEach((node) => {
    if ((node as FormSchemaLayout).isLayout) {
      const layoutItem = node as FormSchemaLayout

      if (typeof layoutItem.children === 'string') {
        staticSchema.push({
          ...getLayoutType(layoutItem),
          children: layoutItem.children,
        })
      } else {
        const childrens = layoutItem.children.map((childNode) => {
          if (typeof childNode === 'string') {
            return childNode
          }
          if ((childNode as FormSchemaLayout).isLayout) {
            const layoutItemChildNode = childNode as FormSchemaLayout

            return {
              ...getLayoutType(layoutItemChildNode),
              children: layoutItemChildNode.children as
                | string
                | FormKitSchemaNode[]
                | FormKitSchemaCondition,
            }
          }

          updateSchemaDataField(childNode as FormSchemaField)
          return buildFormKitField(childNode as FormSchemaField)
        })

        staticSchema.push({
          ...getLayoutType(layoutItem),
          children: childrens,
        })
      }
    }
    // At the moment we support only one level of group/list fields, no recursive implementation.
    else if (
      (node as FormSchemaGroupOrList).type === 'group' ||
      (node as FormSchemaGroupOrList).type === 'list'
    ) {
      const groupOrListField = node as FormSchemaGroupOrList

      const childrenStaticSchema: FormKitSchemaComponent[] = []
      groupOrListField.children.forEach((childField) => {
        childrenStaticSchema.push(buildFormKitField(childField))
        updateSchemaDataField(childField)
      })

      staticSchema.push({
        $cmp: 'FormKit',
        props: {
          type: groupOrListField.type,
          name: groupOrListField.name,
          key: groupOrListField.name,
        },
        children: childrenStaticSchema,
      })
    } else {
      const field = node as FormSchemaField

      staticSchema.push(buildFormKitField(field))
      updateSchemaDataField(field)
    }
  })
}

const localChangeFields = computed(() => {
  // if (props.formSchemaId) return coreWorkflowChanges.value

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

// TODO: maybe we should react on schema changes and rebuild the static schema with a new form-id and re-rendering of
// the complete form (= use the formId as the key for the whole form to trigger the re-rendering of the component...)
if (props.formSchemaId) {
  // TODO: call the GraphQL-Query to fetch the schema.
  toggleInitialLoadingAnimation()
  new QueryHandler(
    useFormSchemaQuery({ formSchemaId: props.formSchemaId }),
  ).watchOnResult((queryResult) => {
    if (queryResult?.formSchema) {
      buildStaticSchema(queryResult.formSchema)
      toggleInitialLoadingAnimation()
    }
  })
} else if (props.schema) {
  // localSchema.value = toRef(props, 'schema').value
  buildStaticSchema(toRef(props, 'schema').value)
}
</script>

<template>
  <FormKit
    v-if="Object.keys(schemaData.fields).length > 0 || $slots.default"
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
