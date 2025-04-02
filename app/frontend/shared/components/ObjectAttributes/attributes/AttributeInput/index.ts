// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import AttributeInput from './AttributeInput.vue'

export default {
  dataTypes: [
    'input',
    'integer',
    'autocompletion_ajax_external_data_source',
    'autocompletion_ajax',
    'autocompletion_ajax_customer_organization',
    'user_autocompletion',
  ], // TODO maybe have own modules for every type, but with shared code, to have an better understanding
  component: AttributeInput,
}
