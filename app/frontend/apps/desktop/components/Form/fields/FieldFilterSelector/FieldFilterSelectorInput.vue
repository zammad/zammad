<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { FormKitSchema } from '@formkit/vue'
import { cloneDeep, isEqual, keyBy, omit } from 'lodash-es'
import { computed, nextTick, ref, shallowRef, toRef, watch } from 'vue'

import useValue from '#shared/components/Form/composables/useValue.ts'
import type { FormFieldContext } from '#shared/components/Form/types/field.ts'
import type { FormFieldValue } from '#shared/components/Form/types.ts'
import type { FilterAttribute } from '#shared/entities/object-attributes/types/store.ts'
import { i18n } from '#shared/i18n.ts'

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

// The filter selector renders its own labels (bypassing FormKit's
// translateWrapperProps), so translate here — including `%s` placeholders,
// which are themselves translated (a config-derived unit key like 'hour(s)';
// plain dynamic placeholders pass through i18n.t unchanged).
const translateFilterLabel = (attribute: Pick<FilterAttribute, 'label' | 'labelPlaceholder'>) =>
  i18n.t(
    attribute.label,
    ...(attribute.labelPlaceholder ?? []).map((placeholder) => i18n.t(placeholder)),
  )

// Exposed to the schema so the legend's `$`-expression re-translates its label
// reactively (on config or locale change), the way a FormKit field label does.
const schemaData = {
  legendLabel: (name: string) => {
    const attribute = attributesByName.value[name]
    return attribute ? translateFilterLabel(attribute) : ''
  },
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
      return { label: translateFilterLabel(currentAttribute), value: currentAttribute.name }
    }

    return {
      label: translateFilterLabel(currentAttribute),
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

// Used for every field. The initial value is seeded declaratively in the schema,
// so here we only sync external value changes into the node and committed
// changes back out. Values are cloned on each hand-off — sharing a reference
// with the node's reactive value aliases the two reactive trees and recurses.
const valueHandlingPlugin = (attributeName: string, inputName: string) => (node: FormKitNode) => {
  // Sync external value updates (taskbar / deep-link restore) into the node; the
  // value-agnostic schema won't rebuild for them on its own.
  const stopExternalSync = watch(
    () => filtersByName.value[attributeName]?.[inputName],
    (updatedValue) => {
      if (isEqual(node._value, updatedValue)) return

      // A container can't take the value via `node.input` (it mangles into the
      // children); set each child directly instead.
      if (node.type !== 'input') {
        if (!Array.isArray(updatedValue)) return

        updatedValue.forEach((slot, index) => {
          const child = node.children?.[index]
          if (child && !isEqual(child._value, slot)) child.input(cloneDeep(slot), false)
        })
        return
      }

      node.input(cloneDeep(updatedValue), false)
    },
  )

  node.on('destroying', stopExternalSync)

  node.on('commit', ({ payload }: { payload: FormFieldValue }) => {
    // Already in sync (e.g. from the external-sync watch) — nothing to write.
    if (isEqual(filtersByName.value[attributeName]?.[inputName], payload)) return

    updateFieldEntry(attributeName, { [inputName]: cloneDeep(payload) })
  })

  // Don't let FormKit inherit this plugin onto child nodes — a child would
  // commit its own value over the container's aggregated one.
  return false
}

// Builds the FormKit schema node for one operator filter-field. Runs inside a
// watcher (not a computed), so it can read the current value to seed `value:`
// without making the schema rebuild on every keystroke.
//
// A single field uses FormKit's own label (translated + associated by the
// form). A compound field (e.g. `in range`) groups its inputs in a native
// `<fieldset>` whose `<legend>` names them; each sub-input keeps its own
// screen-reader-only FormKit label.
const schemaFilterField = (
  attribute: FilterAttribute,
  fieldSchema: FilterField,
): FormKitSchemaNode => {
  const { type, name, children, props: fieldProps, ...inputProps } = fieldSchema
  const inputName = name ?? 'value'

  const nodeId = inputIdFor(attribute.name, inputName)

  const node: Record<string, unknown> = {
    ...inputProps,
    ...fieldProps,
    $formkit: type,
    id: nodeId,
    key: nodeId,
    name: inputName,
    // Clone deep is needed for values which have a complex structure (e.g. arrays for list usage).
    value: cloneDeep(filtersByName.value[attribute.name]?.[inputName]),
    classes: {
      outer: 'w-full',
    },
    alternativeBackground: true,
    ignore: true,
    plugins: [valueHandlingPlugin(attribute.name, inputName)],
  }

  // A compound field renders its `children`: the inputs FormKit aggregates into
  // the container value, plus any plain-string separators. Each input keeps its
  // own screen-reader-only label; the surrounding fieldset/legend (below) names
  // the group — so a screen reader reads e.g. "Escalation count", then "min" /
  // "max".
  if (type === 'list' || type === 'group') {
    const rowChildren = (children ?? []).map((child, index) => {
      if (typeof child === 'string') {
        // DOM-only separator (e.g. `-`), invisible to the list's aggregation.
        return {
          $el: 'span',
          attrs: { class: 'flex h-10 shrink-0 items-center' },
          children: child,
        } as FormKitSchemaNode
      }

      const { type: childType, props: childProps, ...childRest } = child
      const childId = inputIdFor(attribute.name, `${inputName}-${index}`)

      // Each input is a normal FormKit field; its `label` names the bound but
      // is rendered screen-reader-only (`labelSrOnly`) — the legend and visible
      // placeholder are the sighted affordances. Input children carry no value
      // plugin — the container owns the value.
      return Object.assign({}, childRest, childProps, {
        $formkit: childType,
        id: childId,
        key: childId,
        classes: { outer: 'w-full' },
        alternativeBackground: true,
        labelSrOnly: true,
      }) as FormKitSchemaNode
    })

    node.children = [
      {
        $el: 'div',
        attrs: { class: 'flex w-full items-end gap-2' },
        children: rowChildren,
      },
    ]

    // Group the inputs in a native fieldset; the legend names them and carries
    // the attribute label (+ any placeholder) via our own translation.
    return {
      $el: 'fieldset',
      attrs: { class: 'flex w-full min-w-0 flex-col border-0 p-0' },
      children: [
        {
          $el: 'legend',
          attrs: {
            // `cursor-default` so the clickable legend matches a field label.
            class: 'mb-1 block w-fit cursor-default text-sm text-gray-100 dark:text-neutral-400',
            // A `<legend>` has no native click-to-focus (a `<label for>` would
            // double-label the first input), so focus it ourselves.
            onClick: () => focusFieldInput(attribute.name),
          },
          children: [`$legendLabel('${attribute.name}')`],
        },
        node as FormKitSchemaNode,
      ],
    } as FormKitSchemaNode
  }

  // Single field: FormKit renders its own label, translated by the form's
  // `translateWrapperProps` (with `labelPlaceholder` interpolated where present).
  node.label = attribute.label
  node.labelPlaceholder = attribute.labelPlaceholder
  return node as FormKitSchemaNode
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

// Rebuilt only on row-structure changes, never on value edits — a watcher
// rather than a computed, so the build can read current values to seed fields
// declaratively (see `schemaFilterField`) without that read re-running it.
const buildFilterFieldsSchema = (): FormKitSchemaNode[] =>
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
                tooltip: __('Remove filter'),
                onClick: () => removeField(row.name),
              },
            },
          ],
        },
      ],
    } as FormKitSchemaNode
  })

// `shallowRef`: the schema holds component references (`$cmp`) that must not be
// deep-reactive-wrapped, and it's replaced wholesale on each rebuild.
const filterFieldsSchema = shallowRef<FormKitSchemaNode[]>([])

watch(rowStructure, () => (filterFieldsSchema.value = buildFilterFieldsSchema()), {
  immediate: true,
})
</script>

<template>
  <fieldset class="bg-blue-200 dark:bg-gray-700" :name="context.node.name">
    <ul class="grid grid-cols-4 items-end gap-x-6 gap-y-3">
      <FormKitSchema :schema="filterFieldsSchema" :data="schemaData" />

      <li v-if="addFieldActive">
        <FormKit
          :id="selectorNodeId"
          type="treeselect"
          :options="fieldOptions"
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
