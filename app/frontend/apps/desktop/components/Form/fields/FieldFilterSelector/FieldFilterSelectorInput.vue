<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { FormKitSchema } from '@formkit/vue'
import { isEqual, keyBy, omit } from 'lodash-es'
import { computed, nextTick, ref, toRef, watch } from 'vue'

import useValue from '#shared/components/Form/composables/useValue.ts'
import type { FormFieldContext } from '#shared/components/Form/types/field.ts'
import type { FormFieldValue } from '#shared/components/Form/types.ts'
import type { FilterAttribute } from '#shared/entities/object-attributes/types/store.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'

import { operators } from './operators/index.ts'

import type {
  FilterField,
  FilterSelectorEntry,
  FilterSelectorProps,
  FilterSelectorRow,
} from './types.ts'
import type { FormKitNode, FormKitSchemaNode } from '@formkit/core'

interface Props {
  context: FormFieldContext<FilterSelectorProps>
}

const props = defineProps<Props>()

const contextReactive = toRef(props, 'context')

const { localValue } = useValue<FilterSelectorEntry[]>(contextReactive)

const activeFilters = computed<FilterSelectorEntry[]>(() =>
  Array.isArray(localValue.value) ? localValue.value : [],
)

const filtersByName = computed(() => keyBy(activeFilters.value, 'name'))

const attributesByName = computed<Record<string, FilterAttribute>>(() => {
  const orderedAttributes = keyBy(props.context.filterAttributes, 'name')

  if (props.context.filterAttributesOverride)
    props.context.filterAttributesOverride.forEach((attribute) => {
      if (!orderedAttributes[attribute.name]) return

      orderedAttributes[attribute.name] = Object.assign(
        omit(orderedAttributes[attribute.name], 'name'),
        attribute,
      )
    })

  return orderedAttributes
})

// Structural identity of the rows (attribute + operator, value excluded).
// Pure value writes don't change this — the prev-compare returns the
// previous reference so downstream computeds (and the schema) don't
// invalidate until a row is added, removed, or has its operator changed.
const rowStructure = computed<FilterSelectorRow[]>((currentValue) => {
  const newStructure = activeFilters.value.flatMap<FilterSelectorRow>((entry) => {
    const attribute = attributesByName.value[entry.name]
    return attribute ? [{ name: entry.name, attribute, operator: entry.operator }] : []
  })

  return currentValue && isEqual(currentValue, newStructure) ? currentValue : newStructure
})

const selectedAttributeNames = computed(() => rowStructure.value.map((row) => row.name))

// Already-selected attributes are excluded; remaining ones have their
// operator list narrowed to operators whose `filterFields` returns inputs
// for this attribute. Attributes with no usable operator drop entirely.
const availableAttributes = computed<FilterAttribute[]>(() =>
  props.context.filterAttributes.flatMap((attribute) => {
    if (selectedAttributeNames.value.includes(attribute.name)) return []

    const supportedOperators = attribute.operators.filter((operator) =>
      Array.isArray(operators[operator]?.filterFields(attribute)),
    )
    if (supportedOperators.length === 0) return []
    if (supportedOperators.length === attribute.operators.length) return [attribute]
    return [{ ...attribute, operators: supportedOperators }]
  }),
)

// A single treeselect picks attribute + operator in one click. Leaves for
// attributes with multiple operators encode both as `name DELIM operator`;
// attributes with a single operator pass just the name (no delimiter needed),
// and we resolve the operator at pick time.
const ATTRIBUTE_OPERATOR_DELIMITER = '::'

const encodeFieldOption = (name: string, operator: string | null) =>
  operator === null ? name : `${name}${ATTRIBUTE_OPERATOR_DELIMITER}${operator}`

const decodeFieldOption = (value: string): { name: string; operator: string | null } => {
  const [name, operator] = value.split(ATTRIBUTE_OPERATOR_DELIMITER)
  return { name, operator: operator || null }
}

const fieldOptions = computed(() =>
  availableAttributes.value.map((attribute) => {
    let currentAttribute = { ...attribute }

    if (props.context.filterAttributesOverride)
      props.context.filterAttributesOverride.forEach((attribute) => {
        if (currentAttribute.name !== attribute.name) return

        currentAttribute = Object.assign(omit(currentAttribute, 'name'), attribute)
      })

    if (currentAttribute.operators.length <= 1) {
      return { label: currentAttribute.label, value: currentAttribute.name }
    }

    return {
      label: currentAttribute.label,
      value: currentAttribute.name,
      children: currentAttribute.operators.map((operator) => ({
        label: operators[operator]?.label ?? operator,
        value: encodeFieldOption(currentAttribute.name, operator),
      })),
    }
  }),
)

const hasReachedMax = computed(
  () => props.context.max !== undefined && rowStructure.value.length >= props.context.max,
)

const hasReachedMin = computed(
  () => props.context.min !== undefined && rowStructure.value.length <= props.context.min,
)

const canAddField = computed(() => !hasReachedMax.value && availableAttributes.value.length > 0)

const selectorNodeId = `${props.context.id}-field-selector`

const inputIdFor = (attributeName: string, suffix: string) =>
  `${props.context.id}-${attributeName}-${suffix}`

const addFieldActive = ref(false)

// Focus the first input belonging to a row. CSS attribute-prefix selector
// matches any element whose id starts with the row's prefix; the first one
// in document order is the row's first input regardless of operator shape.
const focusFieldInput = (attributeName: string) => {
  const rowPrefix = inputIdFor(attributeName, '')

  nextTick(() => {
    requestAnimationFrame(() => {
      document.querySelector<HTMLElement>(`[id^="${rowPrefix}"]`)?.focus()
    })
  })
}

const addField = (attribute: FilterAttribute, operator: string) => {
  props.context.node.input(
    activeFilters.value.concat({
      name: attribute.name,
      operator,
      value: undefined,
    }),
  )

  focusFieldInput(attribute.name)
}

// The treeselect's `:auto-open-dropdown` prop opens its dropdown on mount.
// `dropdown-close` fires only after a real open (paired with `dropdown-open`
// on the FormKit node).
const bindSelectorEvents = (node: FormKitNode) => {
  node.on('dropdown-close', () => {
    // node.input() sets _value synchronously, so a non-null _value means
    // the dropdown closed because of a pick — will close us once the commit propagates.
    if (addFieldActive.value && !node.context?._value) addFieldActive.value = false
  })
}

const onFilterSelectorPick = (composite: string | null) => {
  if (!composite) return

  const decoded = decodeFieldOption(composite)
  const attributeToAdd = availableAttributes.value.find((a) => a.name === decoded.name)
  if (attributeToAdd) {
    // No operator in the encoded value → attribute has a single operator,
    // use it. Otherwise validate the picked operator against the attribute.
    const operator = decoded.operator ?? attributeToAdd.operators[0]
    if (attributeToAdd.operators.includes(operator)) {
      addField(attributeToAdd, operator)
    }
  }

  addFieldActive.value = false
}

const showFieldSelection = () => {
  if (!canAddField.value) return

  addFieldActive.value = true
}

const updateFieldEntry = (attributeName: string, patch: Partial<FilterSelectorEntry>) => {
  // Updates only apply to existing rows. Adding a row is handled exclusively
  // by `addField`, which sets the operator from the user's pick.
  if (!filtersByName.value[attributeName]) return

  props.context.node.input(
    activeFilters.value.map((entry) =>
      entry.name === attributeName ? { ...entry, ...patch } : entry,
    ),
  )
}

const removeField = (attributeName: string) => {
  if (hasReachedMin.value) return

  props.context.node.input(activeFilters.value.filter((entry) => entry.name !== attributeName))
}

const valueHandlingPlugin = (attributeName: string, inputName: string) => (node: FormKitNode) => {
  // Set initial value, when it exists, otherwise it's not needed.
  const initial = filtersByName.value[attributeName]?.[inputName]

  if (initial !== undefined && initial !== null) node.input(initial, false)

  // External value updates taskbar subscriptions need to be pushed into
  // the node — `rowStructure` is intentionally value-agnostic, so the schema
  // doesn't re-render on pure value changes and the input would otherwise
  // keep showing its mount-time value.
  const stopExternalSync = watch(
    () => filtersByName.value[attributeName]?.[inputName],
    (updatedValue) => {
      if (isEqual(node._value, updatedValue)) return

      node.input(updatedValue, false)
    },
  )

  node.on('destroying', stopExternalSync)

  node.on('commit', ({ payload }: { payload: FormFieldValue }) => {
    // Skip updates from the external-sync watch above
    // Otherwise, the we would end up rippling down the values
    if (isEqual(filtersByName.value[attributeName]?.[inputName], payload)) return

    updateFieldEntry(attributeName, { [inputName]: payload })
  })
}

// Renders one of the operator's filter-field schema fragments into a FormKit
// schema node.
//
// TODO: row labelling needs to be revisited once operators beyond `matches`
// land. The current fallback to `attribute.label` only works for single-input
// operators where the operator label can be implicit. Compound operators
// (`between`, `is empty`, …) need a real composition rule that combines
// attribute label, operator label, and per-filterField labels — likely a
// small helper, owned at the renderer level, not the per-field level.
const schemaFilterField = (
  attribute: FilterAttribute,
  fieldSchema: FilterField,
): FormKitSchemaNode => {
  const { type, name, ...inputProps } = fieldSchema
  const inputName = name ?? 'value'

  const nodeId = inputIdFor(attribute.name, inputName)
  return {
    ...inputProps,
    $formkit: type,
    id: nodeId,
    key: nodeId,
    name: inputName,
    classes: {
      outer: 'w-[22.1875rem]',
    },
    label: attribute.label,
    alternativeBackground: true,
    ignore: true,
    plugins: [valueHandlingPlugin(attribute.name, inputName)],
  } as FormKitSchemaNode
}

const resolveOperatorFilterFields = (attribute: FilterAttribute, operator: string) => {
  const baseFilterFields = operators[operator].filterFields(attribute) ?? []
  const operatorProps = attribute?.operatorFilterProps?.[operator]

  // For relation-typed attributes the resolver omits `options`, so this
  // form-updater entry is the only source. For static-options attributes
  // the form-updater never sends a key for them, so this is undefined.
  const filterOptions = props.context.filterAttributeOptions?.[attribute.name]

  return baseFilterFields.map(({ props: baseProps, ...rest }) => {
    const schema = Object.assign({}, rest, baseProps, operatorProps)
    if (filterOptions !== undefined) schema.options = filterOptions
    return schema
  })
}

const filterFieldsSchema = computed<FormKitSchemaNode[]>(() =>
  rowStructure.value.map((row) => {
    const filterOperatorFields = resolveOperatorFilterFields(row.attribute, row.operator)

    const filterSchema = filterOperatorFields.map((fieldSchema) =>
      schemaFilterField(row.attribute, fieldSchema),
    )

    return {
      $el: 'li',
      attrs: {
        class: 'flex gap-2',
      },
      children: [
        ...filterSchema,
        {
          $el: 'div',
          attrs: {
            class: 'h-10 flex items-center self-end',
          },
          children: [
            {
              $cmp: CommonButton,
              props: {
                icon: 'x-lg',
                variant: 'remove',
                disabled: hasReachedMin.value,
                title: __('Remove attribute'),
                onClick: () => removeField(row.name),
              },
            },
          ],
        },
      ],
    } as FormKitSchemaNode
  }),
)
</script>

<template>
  <fieldset class="bg-blue-200 dark:bg-gray-700" :name="context.node.name">
    <ul class="flex flex-wrap items-end gap-6">
      <FormKitSchema :schema="filterFieldsSchema" />

      <li v-if="addFieldActive">
        <FormKit
          :id="selectorNodeId"
          type="treeselect"
          :options="fieldOptions"
          :classes="{
            outer: 'w-75',
          }"
          :multiple="false"
          :placeholder="$t('Select attribute')"
          :clearable="false"
          :alternative-background="true"
          :auto-open-dropdown="true"
          :label="$t('Add filter')"
          :no-auto-preselect="true"
          :ignore="true"
          @node="bindSelectorEvents"
          @input="onFilterSelectorPick($event as string | null)"
        />
      </li>

      <li v-else v-show="canAddField" class="flex h-10 items-center">
        <CommonButton prefix-icon="plus-square" @click="showFieldSelection">
          {{ $t('Add filter') }}
        </CommonButton>
      </li>
    </ul>
  </fieldset>
</template>
