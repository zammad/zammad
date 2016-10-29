# Ticket-Attributes

For ticket creation use "X-Zammad-Ticket-Attribute: some value", if you want to change
ticket attributes on follow up, use "X-Zammad-Ticket-FollowUp-Attribute: some value".


## X-Zammad-Ticket-Priority

Example: X-Zammad-Ticket-Priority: (1 low|2 normal|3 high)

Set priority of ticket (for whole list check your database).


## X-Zammad-Ticket-Group

Example: X-Zammad-Ticket-Group: [one system group]

Presort of group (highest sort priority).


## X-Zammad-Ticket-Owner

Example: X-Zammad-Ticket-Owner: [login of agent]

Assign ticket to agent.


## X-Zammad-Ticket-State

Example: X-Zammad-Ticket-State: (new|open|...)

Set state of ticket (for whole list check your database)! Be careful!

## X-Zammad-Customer-Email

Example: X-Zammad-Customer-Email: [email address]

Set customer via explicit email.


## X-Zammad-Customer-Login

Example: X-Zammad-Customer-Login: [login]

Set customer via explicit login.


# Article-Attributes

Every time if an article is created (new ticket or/and follow up) you can use
"X-Zammad-Article-Attribute: some value".


## X-Zammad-Article-Sender

Example: X-Zammad-Article-Sender: (Agent|System|Customer)

Info about the sender.


## X-Zammad-Article-Type

Example: X-Zammad-Article-Type: (email|phone|fax|sms|webrequest|note|twitter status|direct-message|facebook|...)

Article type (for whole list check your database).


##  X-Zammad-Article-Visibility

Example: X-Zammad-Article-Visibility: (internal|external)

Article visibility.


# Ignore Header

If you want to ignore whole email, just set the "X-Zammad-Ignore" header.

Example: X-Zammad-Ignore: [yes|true]

Ignore this email.