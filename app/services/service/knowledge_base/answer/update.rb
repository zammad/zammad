# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Updates a knowledge base answer: its title and body in one locale, its category, its publication
#   state and its attachments. Every one of them is optional — what is not submitted stays as it is,
#   so a form can save the part it changed.
#
# Not its tags: an existing answer is tagged from its sidebar, straight onto the record
#   (`tagAssignmentAdd`/`tagAssignmentRemove`), so they never travel through here.
class Service::KnowledgeBase::Answer::Update < Service::KnowledgeBase::Answer::Base
  attr_reader :answer, :answer_data, :skip_validators

  # @param answer [KnowledgeBase::Answer] answer to update
  # @param answer_data [Hash] `category`, `title`, `body`, `visibility` (the publication state to
  #   put the answer in) and `form_id` as sent by
  #   Gql::Types::Input::KnowledgeBase::UpdateAnswerInputType; each of them is optional
  # @param kb_locale [KnowledgeBase::Locale, String] locale the submitted title and body are written
  #   into, as record or as system locale code
  # @param skip_validators [Array<Class>] validator exceptions the caller has already been warned
  #   about and chose to override
  def initialize(answer:, answer_data:, kb_locale:, skip_validators: nil)
    @answer              = answer
    @answer_data         = answer_data
    @submitted_kb_locale = kb_locale
    @skip_validators     = skip_validators
  end

  def execute
    # Editing an answer is editing knowledge base content, so it follows the same rule as the
    #   knowledge base itself: only while it is active. Asserted here rather than left to the locale
    #   resolution, which a caller passing a KnowledgeBase::Locale record would skip.
    active_knowledge_base!

    # Editor access to the answer itself is not asked here: the only caller is
    #   Gql::Mutations::KnowledgeBase::Answer::Update, whose `answer_id` argument loads the record
    #   through AnswerPolicy#update? before the service is reached. Where the answer may be *filed*
    #   is a different question, on a record that gate never sees — see #authorize_category_move!.
    ActiveRecord::Base.transaction do
      # Inside the transaction and behind the row lock, because what the validators check is whether
      #   this save would destroy somebody else's — and #attach_files below replays an upload cache
      #   that deletes every non-inline attachment before refilling it. Checked outside, two saves
      #   could both find the answer as they expect it and the second would then delete what the
      #   first had just added. The lock also reloads the answer, so the check reads what is stored
      #   rather than what this request loaded.
      answer.lock!

      validate!

      assign_attributes

      authorize_category_move!

      # One single save, so KnowledgeBase::HasUniqueTitle checks the title against the siblings in
      #   the *new* category, and a rejected move does not leave a saved title behind. It also saves
      #   the translation and its content, which the answer autosaves.
      answer.save!

      attach_files(answer, answer_data[:form_id])

      answer
    end
  end

  private

  def validate!
    Service::KnowledgeBase::Answer::Update::Validator
      .with_current_user(current_user)
      .execute(answer:, answer_data:, kb_locale:, skip_validators:)
  end

  def assign_attributes
    assign_category

    assign_visibility(answer, answer_data[:visibility])
    assign_translation(answer, kb_locale, title: answer_data[:title], body: answer_data[:body])
  end

  # An absent category leaves the answer where it is. A submitted one is checked against the
  #   knowledge base before it is assigned — an answer must not be moved out of the tree whose locale
  #   its translations were written for.
  def assign_category
    return if !answer_data.key?(:category)

    ensure_category_of_knowledge_base!(answer_data[:category])

    answer.category = answer_data[:category]
  end

  # A move has to be allowed at the target as well, which KnowledgeBase::AnswerPolicy#create? answers
  #   for the already reassigned answer — the same split Service::KnowledgeBase::Category::Update
  #   makes for its parent.
  #
  # Only an actual change: for an answer that stays where it is, #create? asks the very same question
  #   as the argument gate's #update? (both resolve the access through the answer's category), so
  #   asking it again would only cost a permission lookup on every save — the form sends the stored
  #   category back each time. Unlike the category case, where #create? asks about the *parent* and a
  #   resubmitted unchanged one would refuse an editor who may edit the category but not its parent.
  def authorize_category_move!
    return if !answer.category_id_changed?

    Pundit.authorize current_user, answer, :create?
  end
end
