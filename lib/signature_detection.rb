# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module SignatureDetection

=begin

try to detect the signature in list of articles for example

  messages = [
    {
      content: 'some content',
      content_type: 'text/plain',
    },
  ]

  signature = SignatureDetection.find_signature(messages)

returns

  signature = '...signature possible match...'

=end

  def self.find_signature(messages)
    signature_candidates = Hash.new(0) # <potential_signature>: <score>
    messages             = messages.map { |m| m[:content_type].match?(%r{text/html}i) ? m[:content].html2text(true) : m[:content] }
    message_pairs        = messages.each_cons(2).to_a
    diffs                = message_pairs.map { |msg_pair| Diffy::Diff.new(*msg_pair).to_s }

    # Find the first 5- to 10-line common substring in each diff
    diffs.map { |d| d.split("\n") }.each do |diff_lines|
      # Get line numbers in diff representing changes (those starting with +, -, \)
      delta_indices = diff_lines.map.with_index { |l, i| l.start_with?(' ') ? nil : i }.compact

      # Add boundaries at start and end
      delta_indices.unshift(-1).push(diff_lines.length)

      # Find first gap of 5+ lines between deltas (i.e., the common substring's location)
      sig_range = delta_indices.each_cons(2)
                               .map { |head, tail| [head + 1, tail - 1] }
                               .find { |head, tail| tail > head + 4 }

      next if sig_range.nil?

      # Take up to 10 lines from this "gap" (i.e., the common substring)
      match_content = diff_lines[sig_range.first..sig_range.last]
                        .map { |l| l.sub(%r{^.}, '') }
                        .first(10).join("\n")

      # Add this substring to the signature_candidates hash and increment its match score
      signature_candidates[match_content] += 1
    end

    signature_candidates.max_by { |_, score| score }&.first
  end

=begin

this function will search for a signature string in a string (e.g. article) and return the line number of the signature start

  signature_line = SignatureDetection.find_signature_line(signature, message, content_type)

returns

  signature_line = 123

  or

  signature_line = nil

=end

  def self.find_signature_line(signature, string, content_type)
    string = string.html2text(true) if content_type.match?(%r{text/html}i)

    # try to find the char position of the signature
    search_position = string.index(signature)

    # count new lines up to signature
    string[0..search_position].split("\n").length + 1 if search_position.present?
  end

=begin

find signature line of message by user and article

  signature_line = SignatureDetection.find_signature_line_by_article(user, article)

returns

  signature_line = 123

  or

  signature_line = nil

=end

  def self.find_signature_line_by_article(user, article)
    return if !user.preferences[:signature_detection]

    SignatureDetection.find_signature_line(
      user.preferences[:signature_detection],
      article.body,
      article.content_type,
    )
  end

=begin

this function will search for a signature string in all articles of a given user_id

  signature = SignatureDetection.by_user_id(user_id)

returns

  signature = '...signature possible match...'

=end

  def self.by_user_id(user_id)
    type = Ticket::Article::Type.lookup(name: 'email')
    sender = Ticket::Article::Sender.lookup(name: 'Customer')
    tickets = Ticket.where(
      created_by_id:            user_id,
      create_article_type_id:   type.id,
      create_article_sender_id: sender.id
    ).limit(5).order(id: :desc)
    article_bodies = []
    tickets.each do |ticket|
      article = ticket.articles.first
      next if !article

      data = {
        content:      article.body,
        content_type: article.content_type,
      }
      article_bodies.push data
    end

    find_signature(article_bodies)
  end

=begin

rebuild signature for each user

  SignatureDetection.rebuild_all_user

returns

  true/false

=end

  def self.rebuild_all_user
    User.select('id').where(active: true).order(id: :desc).each do |local_user|
      rebuild_user(local_user.id)
    end
    true
  end

=begin

rebuild signature detection for user

  SignatureDetection.rebuild_user(user_id)

returns

  true/false

=end

  def self.rebuild_user(user_id)
    signature_detection = by_user_id(user_id)
    return if !signature_detection

    user = User.find(user_id)
    return if user.preferences[:signature_detection] == signature_detection

    user.preferences[:signature_detection] = signature_detection
    user.save

    true
  end

=begin

rebuild signature for all articles

  SignatureDetection.rebuild_all_articles

returns

  true/false

=end

  def self.rebuild_all_articles
    article_type = Ticket::Article::Type.lookup(name: 'email')

    Ticket::Article.where(type_id: article_type.id)
                   .order(id: :desc)
                   .find_each(batch_size: 10) do |article|
      user = User.lookup(id: article.created_by_id)
      next if !user.preferences[:signature_detection]

      signature_line = find_signature_line(
        user.preferences[:signature_detection],
        article.body,
        article.content_type,
      )
      next if !signature_line

      article.preferences[:signature_detection] = signature_line
      article.save if article.changed?
    end
    true
  end

end
