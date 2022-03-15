<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<template>
  <FormKit
    v-if="Object.keys(schemaData.fields).length > 0 || $slots.fields"
    v-bind:id="formId"
    v-model="values"
    type="form"
    v-bind:config="formConfig"
    v-bind:form-class="localClass"
    v-bind:actions="false"
    v-bind:incomplete-message="false"
    v-bind:plugins="localFormKitPlugins"
    v-bind:sections-schema="formKitSectionsSchema"
    v-on:node="setFormNode"
    v-on:submit="onSubmit"
  >
    <slot name="before-fields" />
    <template v-if="!$slots.fields">
      <FormKitSchema
        v-bind:schema="staticSchema"
        v-bind:data="schemaData"
        v-bind:library="additionalComponentLibrary"
      />
    </template>
    <template v-else>
      <slot name="fields" />
    </template>
    <slot name="after-fields" />
  </FormKit>
</template>

<script setup lang="ts">
import { FormKit, FormKitSchema } from '@formkit/vue'
import FormLayout from '@common/components/form/FormLayout.vue'
import {
  computed,
  ref,
  reactive,
  toRef,
  watch,
  markRaw,
  ConcreteComponent,
  nextTick,
} from 'vue'
import {
  type FormSchemaField,
  type FormSchemaLayout,
  type FormSchemaNode,
  type FormValues,
  type ReactiveFormSchemData,
  FormValidationVisibility,
} from '@common/types/form'
import type {
  FormKitGroupValue,
  FormKitPlugin,
  FormKitSchemaNode,
  FormKitSchemaCondition,
  FormKitNode,
  FormKitClasses,
  FormKitSchemaDOMNode,
  FormKitSchemaComponent,
} from '@formkit/core'
import getUuid from '@common/utils/getUuid'

// TODO:
// - Do we need a loading animation?
// - Maybe some default buttons inside the components with loading cycle on submit?
// - Disabled form on submit? (i think it's the default of FormKit)
// - Reset/Clear form handling?
// - ...

// TODO:
interface Props {
  schema?: FormSchemaNode[]
  formName?: string
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
}

const formId = `form-${getUuid()}`

const props = withDefaults(defineProps<Props>(), {
  schema: () => {
    return []
  },
  changeFields: () => {
    return {}
  },
  staticSchema: false,
  validationVisibility: FormValidationVisibility.blur,
})

// Rename prop 'class' for usage in the template, because of reserved word
const localClass = toRef(props, 'class')

const emit = defineEmits<{
  (e: 'submit', values: FormKitGroupValue): void
  (e: 'changed', fieldName: string, newValue: unknown): void
}>()

let formNode: FormKitNode
const setFormNode = (node: FormKitNode) => {
  formNode = node

  // TODO: maybe we should also emit the node one level above to have the node available without a own getNode-call...
}

const onSubmit = (values: FormKitGroupValue) => {
  const emitValues = {
    ...values,
    formId,
  }

  emit('submit', emitValues)
}

const changedValuePlugin = (node: FormKitNode) => {
  node.on('input', ({ payload: value, origin: node }) => {
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
const additionalComponentLibrary = {
  FormLayout: markRaw(FormLayout) as ConcreteComponent,
}

const values = ref<FormValues>({})

// Define the static schema, which will be filled with the real fields from the `schemaData`.
const staticSchema: FormKitSchemaNode[] = []

const schemaData = reactive<ReactiveFormSchemData>({
  fields: {},
})

const updateSchemaDataField = (field: FormSchemaField) => {
  const newField = {
    ...field,
    show: field.show ?? true,
  }

  if (schemaData.fields[field.name]) {
    schemaData.fields[field.name] = Object.assign(
      schemaData.fields[field.name],
      newField,
    )
  } else {
    schemaData.fields[field.name] = newField
  }
}

const buildStaticSchema = (schema: FormSchemaNode[]) => {
  const buildFormKitField = (
    field: FormSchemaField,
  ): FormKitSchemaComponent => {
    return {
      $cmp: 'FormKit',
      if: `$fields.${field.name}.show`,
      bind: `$fields.${field.name}`,
      props: {
        type: field.type,
        key: field.name,
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
            return {
              ...getLayoutType(childNode as FormSchemaLayout),
              children: childNode.children as
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
    } else {
      const field = node as FormSchemaField

      // TODO: maybe we can also add better support for Group and List fields, when this bug is fixed:
      // https://github.com/formkit/formkit/issues/91

      staticSchema.push(buildFormKitField(field))

      updateSchemaDataField(field)
    }
  })
}

const coreWorkflowChanges = ref<Record<string, FormSchemaField>>({})

// TODO: coreWorkflowChanges should be filled from the server call...

const localChangeFields = computed(() => {
  if (props.formName) return coreWorkflowChanges.value

  return props.changeFields
})

// If something changed in the change fields, we need to update the current schemaData
watch(localChangeFields, (newChangeFields) => {
  Object.keys(newChangeFields).forEach((fieldName) => {
    const field = {
      ...newChangeFields[fieldName],
      name: fieldName,
    }

    updateSchemaDataField(field)

    nextTick(() => {
      if (field.value !== values.value[fieldName]) {
        formNode.at(fieldName)?.input(field.value)
      }
    })
  })
})

// TODO: maybe we should react on schema changes and rebuild the static schema with a new form-id and re-rendering of
// the complete form (= use the formId as the key for the whole form to trigger the re-rendering of the component...)
if (props.formName) {
  // TODO: call the GraphQL-Query to fetch the schema.
  setTimeout(() => {
    buildStaticSchema(toRef(props, 'schema').value)
  }, 4000)
} else if (props.schema) {
  // localSchema.value = toRef(props, 'schema').value
  buildStaticSchema(toRef(props, 'schema').value)
}
</script>
