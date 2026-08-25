// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { empty } from '@formkit/utils'

import { i18n } from '#shared/i18n.ts'

import type { FormKitNode } from '@formkit/core'
import type { FormKitValidationRule } from '@formkit/validation'

const RULE_NAME = 'radioListOptionDate'

// An option that owns a date field is answered by that date alone: what the field commits is the
//   timestamp, so picking such an option leaves the field empty until a date is there. The picker
//   cannot report that itself - it is rendered detached from the form (`ignore`), so neither its
//   value nor its validation ever reaches the form the option is part of.
const optionDateRequired: FormKitValidationRule = (node) =>
  !node.props.dateOptionSelected || !empty(node.value)

// The state to catch *is* an empty value, which a rule is not run for by default.
optionDateRequired.skipEmpty = false

const addRuleToValidationProp = (
  // oxlint-disable-next-line no-explicit-any
  validation: string | Array<[rule: string, ...args: any]>,
) => {
  if (Array.isArray(validation)) return [...validation, [RULE_NAME]]

  return validation ? `${validation}|${RULE_NAME}` : RULE_NAME
}

const addOptionDateValidation = (node: FormKitNode) => {
  // Set by the input component while the selected option owns a date field. The rule reads it off
  //   the node, which is what makes the validation re-run when the *selection* changes and not
  //   only when a value is committed: @formkit/observer subscribes to every prop a rule touches.
  node.addProps(['dateOptionSelected'])

  node.on('created', () => {
    node.props.validationRules = {
      ...node.props.validationRules,
      [RULE_NAME]: optionDateRequired,
    }

    node.props.validationMessages = {
      ...node.props.validationMessages,
      [RULE_NAME]: () => i18n.t('This field is required.'),
    }

    node.props.validation = addRuleToValidationProp(node.props.validation)
  })
}

export default addOptionDateValidation
