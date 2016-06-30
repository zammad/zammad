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

    string_list = []
    messages.each { |message|
      if message[:content_type] =~ %r{text/html}i
        string_list.push message[:content].html2text(true)
        next
      end
      string_list.push message[:content]
    }

    # hash with possible signature and count of matches in string list
    possible_signatures = {}

    # loop all strings in array
    string_list.each_with_index { |_main_string, main_string_index|
      break if main_string_index + 1 > string_list.length - 1

      # loop all all strings in array except of the previous index
      ( main_string_index + 1..string_list.length - 1 ).each { |second_string_index|

        # get content of string 1
        string1_content = string_list[main_string_index]

        # get content of string 2
        string2_content = string_list[second_string_index]

        # diff strings
        diff_result = Diffy::Diff.new(string1_content, string2_content)

        # split diff result by new line
        diff_result_array = diff_result.to_s.split("\n")

        # define start index for blocks with no difference
        match_block = nil

        # loop of lines of the diff result
        ( 0..diff_result_array.length - 1 ).each { |diff_string_index|

          # if no block with difference is defined then we try to find a string block without a difference
          if !match_block
            match_block = diff_string_index
          end

          # get line of diff result with current loop inde
          line = diff_result_array[diff_string_index]

          # check if the line starts with
          # + = new content incoming
          # - = removed content
          # \ = end of file
          # or if the current line is the last line of the diff result
          next if line !~ /^(\\|\+|\-)/i && diff_string_index != diff_result_array.length - 1

          # if the count of the lines without any difference is higher than 4 lines
          if diff_string_index - match_block > 4

            # define the block size without any difference
            # except "-" because in this case 1 line is removed to much
            match_block_total = diff_string_index + (line =~ /^(\\|\+)/i ? -1 : 0)

            # get string of possible signature, use only the first 10 lines
            match_max_content = 0
            match_content = ''
            ( match_block..match_block_total ).each { |match_block_index|
              break if match_max_content == 10
              match_max_content += 1
              match_content += "#{diff_result_array[match_block_index][1..-1]}\n"
            }

            # count the match of the signature in string list to rank
            # the signature
            possible_signatures[match_content] ||= 0
            possible_signatures[match_content] += 1

            break
          end

          match_block = nil
        }
      }
    }

    # loop all possible signature by rating and return highest rating
    possible_signatures.sort { |a1, a2| a2[1].to_i <=> a1[1].to_i }.map do |content, _score|
      return content.chomp
    end

    nil
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

    if content_type =~ %r{text/html}i
      string = string.html2text(true)
    end

    # try to find the char position of the signature
    search_position = string.index(signature)

    return if search_position.nil?

    # count new lines up to signature
    string[0..search_position].split("\n").length + 1
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
      created_by_id: user_id,
      create_article_type_id: type.id,
      create_article_sender_id: sender.id
    ).limit(5).order(id: :desc)
    article_bodies = []
    tickets.each { |ticket|
      article = ticket.articles.first
      next if !article
      data = {
        content: article.body,
        content_type: article.content_type,
      }
      article_bodies.push data
    }

    find_signature(article_bodies)
  end

=begin

rebuild signature for each user

  SignatureDetection.rebuild_all_user

returns

  true/false

=end

  def self.rebuild_all_user
    User.select('id').where(active: true).order(id: :desc).each { |local_user|
      rebuild_user(local_user.id)
    }
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
    Ticket::Article.select('id').where(type_id: article_type.id).order(id: :desc).each { |local_article|
      article = Ticket::Article.find(local_article.id)
      user = User.find(article.created_by_id)
      next if !user.preferences[:signature_detection]

      signature_line = find_signature_line(
        user.preferences[:signature_detection],
        article.body,
        article.content_type,
      )
      next if !signature_line
      next if article.preferences[:signature_detection] == signature_line

      article.preferences[:signature_detection] = signature_line
      article.save
    }
    true
  end

end
