// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { type FunctionDirective, type ObjectDirective } from 'vue'

export type DirectiveRecord = Record<string, FunctionDirective | ObjectDirective>
