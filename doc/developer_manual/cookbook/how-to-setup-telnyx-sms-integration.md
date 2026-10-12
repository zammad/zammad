# How to Setup Telnyx SMS Integration

Zammad can receive and send SMS through [Telnyx](https://telnyx.com/) next to the existing Twilio, MessageBird and
Massenversand providers. The driver lives in `app/models/channel/driver/sms/telnyx.rb` and talks to the
[Telnyx Messaging API v2](https://developers.telnyx.com/docs/messaging/messages) directly via `UserAgent` and
OpenSSL, without an SDK dependency.

## Configure Telnyx

1. Create an **API key** in the Telnyx Mission Control Portal (**Keys & Credentials > API Keys**).
2. Copy the account **public key** from **Keys & Credentials > Public Key**. It is a Base64 string
   of 44 characters that encodes the raw 32-byte Ed25519 key Telnyx signs all webhooks with.
3. Create (or reuse) a **messaging profile** and assign the phone number Zammad should send from.
4. Set the messaging profile's **inbound webhook URL** to the webhook of the Zammad channel (see below). Telnyx needs
   to reach the URL via HTTPS and expects a `2xx` response within two seconds.

## Configure Zammad

Navigate to **Channels > SMS** in the admin interface.

### Account (inbound and outbound)

1. Click **New** under **SMS Accounts** and choose the provider **Telnyx**.
2. Copy the generated **Webhook** URL (`https://<fqdn>/api/v1/sms_webhook/<webhook token>`) into the messaging
   profile at Telnyx.
3. Fill in the **API key**, the **Public key**, the **Sender** number in E.164 format (`+15551234567`) and the
   **Destination Group** for new tickets.
4. **Test** sends a real message via the API with the configuration currently in the form.

### Notification (outbound only)

A notification channel only needs the **API key** and the **Sender**. It is used by triggers and schedulers that send
SMS notifications, so it does not require a public key: no webhooks are received for it.

## How inbound webhooks are processed

Every request to the webhook URL of a Telnyx channel is verified before anything else is read from it:

- The request must be a `POST` and carry the `telnyx-signature-ed25519` and `telnyx-timestamp` headers.
- The timestamp must be within 300 seconds of the server time, in both directions, matching the
  [Telnyx Ruby SDK](https://github.com/team-telnyx/telnyx-ruby/blob/master/lib/telnyx/lib/webhook_verification.rb).
- The Base64 signature must verify with the configured public key over the string `<timestamp>|<raw request body>`,
  using the request body bytes exactly as they were sent.

A failed verification answers `403` and marks the channel's inbound status as failed, so an admin can see a wrong
public key in the overview. A missing or unparsable public key answers `422` instead. In both cases no ticket, article
or user is created. Other SMS providers are not affected by this check.

After verification the driver parses the raw body itself and ignores anything the Rails parameter parser merged in
from the query string or a form body. It handles the events like this:

| Event                                                           | Result                                                 |
| --------------------------------------------------------------- | ------------------------------------------------------ |
| `message.received`                                              | Article in an open SMS ticket of the sender, or new ticket |
| `message.received` with a `payload.id` already stored           | `200`, nothing created (Telnyx retries webhooks)       |
| `message.received` with text and media both empty               | `422`, nothing created                                 |
| `message.received` without `payload.id`, `from` or `to` numbers | `422`, nothing created                                 |
| `message.sent`, `message.finalized`, any other event type       | `200`, nothing created                                 |
| Body that is not a JSON object                                  | `400` or `422`, nothing created                        |

The customer is matched via the sender number (`User.by_mobile`), the open ticket via the customer and the `sms`
article type, both exactly like the Twilio driver. Media-only messages (MMS) create an article with an empty body.
The media list from the payload (`url`, `content_type`, `sha256`, `size`) is stored in the article preferences under
`sms.media`; the files are not downloaded, which matches the Twilio behaviour for `NumMedia`.

## How outbound messages are sent

Agent replies with the `sms` article type and SMS notifications are delivered by `CommunicateSmsJob`, which calls the
driver with the first 160 characters of the article body. This limit is shared by all SMS providers. The driver posts

```http
POST https://api.telnyx.com/v2/messages
Authorization: Bearer <API key>
Content-Type: application/json; charset=utf-8

{"from":"<Sender>","to":"<recipient>","text":"<message>"}
```

and treats the delivery as successful only when the response is a `2xx` whose `data.id` contains the accepted
message id. Any other response raises with the HTTP status and the `errors[].code/title/detail` from the response
body, which ends up in the article's delivery status and in the channel's outbound status. As for the other providers,
nothing is sent while `developer_mode` or `import_mode` is enabled.

## Feature parity with Twilio

| Feature                                  | Twilio                      | Telnyx                                              |
| ---------------------------------------- | --------------------------- | --------------------------------------------------- |
| Account channel (inbound and outbound)   | yes                         | yes                                                 |
| Notification channel (outbound only)     | yes                         | yes                                                 |
| Test send from the admin interface       | yes                         | yes                                                 |
| Group routing of new tickets             | yes                         | yes                                                 |
| Customer matching by mobile number       | yes                         | yes                                                 |
| Follow-ups into the open SMS ticket      | yes                         | yes                                                 |
| New ticket after the previous was closed | yes                         | yes                                                 |
| Duplicate suppression                    | `SmsMessageSid`             | `payload.id`                                        |
| Agent replies and notifications          | yes, 160 characters         | yes, 160 characters                                 |
| Webhook authentication                   | webhook token in the URL    | webhook token in the URL and Ed25519 signature      |
| Delivery status webhooks                 | not sent to Zammad          | accepted and ignored                                |
| Media-only inbound messages              | empty article, `NumMedia`   | empty article, `sms.media` list                     |
| Media download or outbound MMS           | no                          | no                                                  |

## Testing

Specs must never reach the Telnyx API. Outbound requests are stubbed with WebMock, and inbound requests are signed
with a key generated inside the spec. The `sms_telnyx: true` metadata includes `SmsTelnyxHelper`
(`spec/support/sms_telnyx.rb`), which builds the documented webhook payloads and signatures:

```ruby
signing_key = OpenSSL::PKey.generate_key('ED25519')
channel     = create(:sms_telnyx_channel, public_key: telnyx_public_key(signing_key))

body      = telnyx_webhook_body(:inbound_sms1)
timestamp = Time.zone.now.to_i
signature = telnyx_webhook_signature(body, timestamp: timestamp, key: signing_key)

post "/api/v1/sms_webhook/#{channel.options[:webhook_token]}",
     params:  body,
     headers: { 'CONTENT_TYPE' => 'application/json', 'telnyx-timestamp' => timestamp.to_s, 'telnyx-signature-ed25519' => signature }
```

The relevant specs are `spec/models/channel/driver/sms/telnyx_spec.rb`, `spec/requests/integration/telnyx_sms_spec.rb`
and `spec/system/channels/sms_spec.rb`.

## References

- [Telnyx Messaging API: Messages](https://developers.telnyx.com/docs/messaging/messages)
- [Telnyx Messaging API: Receive a message](https://developers.telnyx.com/docs/messaging/messages/receive-message)
- [Telnyx Messaging API: Receiving webhooks](https://developers.telnyx.com/docs/messaging/messages/receiving-webhooks)
- [Telnyx support: How to leverage webhooks](https://support.telnyx.com/en/articles/4334722-how-to-leverage-webhooks)
