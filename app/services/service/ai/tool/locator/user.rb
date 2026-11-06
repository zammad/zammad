# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Finds the user a caller names by its ID or by its email — the ID where both come.
class Service::AI::Tool::Locator::User < Service::AI::Tool::Locator
  locates ::User

  # Written for the model, like every text a tool returns, so not translated.
  # rubocop:disable Zammad/DetectTranslatableString
  PARAMETERS = {
    'user_id' => { type: :integer, description: 'The ID of the user, e.g. 5, as another tool\'s result names it.' },
    'email'   => { type: :string, description: 'The user\'s email address, e.g. "anna@example.com", exactly.' },
  }.freeze

  NO_NAME             = 'Name the user by its user_id or email.'.freeze
  SHARED_EMAIL        = 'Several users have this email. Name the user by its user_id instead.'.freeze
  NOT_FOUND           = 'No user with this user_id or email was found; the email has to match exactly. search_users ' \
                        'finds a user by a part of the name or the email, or by a phone number.'.freeze
  NOT_IN_CONVERSATION = 'Only a user a tool returned here and a user the agent named in their own messages, by email ' \
                        'or ID, can be read. Ask the agent before you read another one.'.freeze
  # rubocop:enable Zammad/DetectTranslatableString

  # How an agent names a user in a message: by the email; by its ID as every object.
  EMAIL_IN_TEXT = %r{[[:alnum:]._%+-]+@[[:alnum:].-]+\.[[:alpha:]]{2,}}

  class << self
    # As User stores an email: in lower case, its domain in Unicode.
    def normalized_email(email)
      email = email.to_s.strip
      return if email.empty?

      EmailHelper::Idn.to_unicode(email).downcase
    end
  end

  # An email is unique unless the system allows several users to share one, or an import brought them in.
  #
  # @return [Integer, nil] the ID of the named user, nil when there is none
  def record_id
    return arguments['user_id'] if !arguments['user_id'].nil?

    email = self.class.normalized_email(arguments['email'])
    return if email.nil?

    ids = ::User.where(email:).limit(2).pluck(:id)
    raise Service::AI::Tool::AmbiguousNameError, SHARED_EMAIL if ids.size > 1

    ids.first
  end

  # Whether the named user is one the conversation may read: one of the given IDs, or one the agent named, by email or
  #   by ID. Named in the same form, it is decided on what was named alone, whether the user exists or not; across the
  #   forms — the agent wrote an email, the call gives an ID — only for a user the caller may see, so that the answer
  #   tells nothing about the others.
  #
  # @param ids [Array<Integer>] the users the conversation may read anyway
  # @param texts [Array<String>] what the agent wrote in the conversation
  # @param user [User] as whom the conversation reads
  def named_by?(ids:, texts:, user:)
    id    = arguments['user_id']
    email = self.class.normalized_email(arguments['email'])
    return false if id.nil? && email.nil?

    ids   += texts.flat_map { |text| text.to_s.scan(ID_IN_TEXT).flatten.map(&:to_i) }
    emails = texts.flat_map { |text| text.to_s.scan(EMAIL_IN_TEXT).map { |written| self.class.normalized_email(written) } }
    return true if id ? ids.include?(id) : emails.include?(email)

    other_form = id ? ::User.where(id:, email: emails) : ::User.where(email:, id: ids)
    other_form.any? { |named| Pundit.policy(user, named).show? }
  end
end
