// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

export type RadioListOptionValue = string | number

// The `datetime` field an option can own, rendered inside the group and below that option while
//   it is selected. Only what a single moment in time needs - no ranges: the option commits one
//   timestamp as the value of the whole field.
//
// Several options of a field may own one, each committing its own timestamp while it is picked.
//   What no field of them can do is tell *which* option a stored timestamp answered - it carries
//   the date alone - so a restored value falls to the first option that takes a date.
export type RadioListOptionDateField = {
  // Accessible name of the picker, rendered visually hidden: the option label above it is what
  //   the user reads.
  label: string
  futureOnly?: boolean
  pastOnly?: boolean
  minDate?: Date | string
  maxDate?: Date | string
}

export type RadioListOption = {
  // An option carrying a `dateField` never commits this value: it identifies the option, while
  //   the value of the field is the timestamp picked below it. `null` is a value of its own - the
  //   option that answers the field by leaving it empty.
  value: RadioListOptionValue | null
  label: string
  description?: string
  dateField?: RadioListOptionDateField
}
