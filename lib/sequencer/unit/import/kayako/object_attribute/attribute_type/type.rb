# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Kayako::ObjectAttribute::AttributeType::Type < Sequencer::Unit::Import::Kayako::ObjectAttribute::AttributeType::Select
  private

  def options
    super.merge(
      'Question' => 'Question',
      'Task'     => 'Task',
      'Problem'  => 'Problem',
      'Incident' => 'Incident',
    )
  end
end
