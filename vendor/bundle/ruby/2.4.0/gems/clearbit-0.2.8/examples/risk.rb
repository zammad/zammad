require 'clearbit'

# Step 1)
# Add the JS library + load it
# https://clearbit.com/docs#risk-api-javascript-library

# Step 2)
result = Clearbit::Risk.calculate(
  email: 'test@example.com',
  ip:    '0.0.0.0'
)

p result
