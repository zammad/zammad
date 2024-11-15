// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

// export const validDateTime = (value: string) =>
//   !Number.isNaN(Date.parse(String(value)))

export const validDateTime = (value: string) => {
  const dateTimeRegex =
    /^(?:\d{4}-\d{2}-\d{2}|(?:\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z)|(?:\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} UTC))$/

  if (!dateTimeRegex.test(value)) return false

  return !Number.isNaN(Date.parse(String(value)))
}

export const isDateString = (value: string) => {
  const dateRegex = /^\d{4}-\d{2}-\d{2}$/

  return dateRegex.test(value)
}
