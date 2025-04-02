# How to Diagnose Email Bugs

Incoming email is a common source of bugs in Zammad — there's simply no way to anticipate all the different kinds of
input the application will receive from the real world. Getting a copy of a raw email will allow you to manually
inspect header fields, check possible text encodings, or simply import the email into your own local development
instance.

You can ask the bug reporter to run the following command on their machine, and then send you the resulting file.
(Obviously, replace `<TICKET_NUMBER>` with the appropriate value.)

```sh
zammad rails r "puts Ticket.find_by(number: '<TICKET_NUMBER>').articles.last.as_raw.content" > /tmp/bug_report_email.eml
```

Then, you can import it into your own development instance via:

```sh
cat /path/to/file.eml | rails r 'Channel::Driver::MailStdin.new'
```
