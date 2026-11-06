# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'services/service/ai/tool/loads_context_object_examples'
require 'services/service/ai/tool/field_scope_examples'

RSpec.describe Service::AI::Tool, :aggregate_failures do
  let(:tool) do
    stub_const('Service::AI::Tool::LookUpPrinter', Class.new(described_class) do
      description 'Look up a printer by its name.'
      effect      :read
      permission  'ticket.agent'
      offered_in  :harness, :mcp
      audiences   :human_agents

      parameter :name,  type: :string,  description: 'The name of the printer.', required: true
      parameter :limit, type: :integer, description: 'How many to return.'
      parameter :state, type: :string,  description: 'The state.', enum: %w[on off]
      parameter :ids,   type: :array,   description: 'The printers.', items: { type: 'integer' }

      def execute
        { user_id: current_user.id, object_id: object_id, arguments: }
      end
    end)
  end

  describe '.input_schema' do
    it 'describes the parameters as a JSON Schema object' do
      expect(tool.input_schema).to eq(
        type:                 'object',
        properties:           {
          'name'  => { type: 'string', description: 'The name of the printer.' },
          'limit' => { type: 'integer', description: 'How many to return.' },
          'state' => { type: 'string', description: 'The state.', enum: %w[on off] },
          'ids'   => { type: 'array', description: 'The printers.', items: { type: 'integer' } },
        },
        required:             %w[name],
        additionalProperties: false,
      )
    end
  end

  describe '.definition' do
    it 'is the definition the provider takes' do
      expect(tool.definition).to be_a(AI::Provider::Completion::ToolDefinition)
        .and have_attributes(name: 'look_up_printer', description: 'Look up a printer by its name.', input_schema: tool.input_schema)
    end
  end

  describe '.argument_errors' do
    it 'accepts arguments that fit' do
      expect(tool.argument_errors({ 'name' => 'Laser', 'limit' => 2, 'state' => 'on' })).to be_empty
      expect(tool.argument_errors({ 'name' => 'Laser', 'limit' => nil })).to be_empty
    end

    it 'names missing, unknown and mistyped arguments' do
      expect(tool.argument_errors({ 'limit' => '2', 'colour' => 'red', 'state' => 'broken' })).to contain_exactly(
        "missing required argument 'name'",
        "unknown argument 'colour'",
        "argument 'limit' must be of type integer",
        "argument 'state' must be one of on, off",
      )
    end

    it 'checks an array against its item type and its allowed values together' do
      combined = Class.new(tool) { parameter :pair, type: :array, description: 'Two.', items: { type: 'integer' }, enum: [[1, 2]] }

      expect(combined.argument_errors({ 'name' => 'Laser', 'pair' => [1, 2] })).to be_empty
      expect(combined.argument_errors({ 'name' => 'Laser', 'pair' => [3, 4] })).to eq(["argument 'pair' must be one of [1,2]"])
    end

    it 'checks the elements of an array against its declared item type' do
      expect(tool.argument_errors({ 'name' => 'Laser', 'ids' => [1, 2] })).to be_empty
      expect(tool.argument_errors({ 'name' => 'Laser', 'ids' => ['wrong', nil, {}] }))
        .to eq(["argument 'ids' must contain only values of type integer"])
    end
  end

  describe 'defaults and bounds' do
    let(:bounded) { Class.new(tool) { parameter :limit, type: :integer, description: 'How many.', default: 3, minimum: 1, maximum: 10 } }

    it 'puts them into the input schema' do
      expect(bounded.input_schema[:properties]['limit']).to eq(type: 'integer', description: 'How many.', default: 3, minimum: 1, maximum: 10)
    end

    it 'checks the bounds' do
      expect(bounded.argument_errors({ 'name' => 'Laser', 'limit' => 0 })).to eq(["argument 'limit' must be at least 1"])
      expect(bounded.argument_errors({ 'name' => 'Laser', 'limit' => 11 })).to eq(["argument 'limit' must be at most 10"])
      expect(bounded.argument_errors({ 'name' => 'Laser', 'limit' => 10 })).to be_empty
    end

    it 'gives the default for an argument the model left out' do
      expect(bounded.new(arguments: {}).argument(:limit)).to eq(3)
      expect(bounded.new(arguments: { 'limit' => 5 }).argument(:limit)).to eq(5)
    end

    it 'takes bounds only for numbers' do
      expect { Class.new(described_class) { parameter :x, type: :string, description: 'X', maximum: 3 } }
        .to raise_error(ArgumentError, 'bounds need a number: x')
    end
  end

  describe '.parameter' do
    it 'rejects a type JSON Schema does not know' do
      expect { Class.new(described_class) { parameter :x, type: :text, description: 'X' } }
        .to raise_error(ArgumentError, 'unknown parameter type: :text')
      expect { Class.new(described_class) { parameter :x, type: :array, description: 'X', items: { type: 'text' } } }
        .to raise_error(ArgumentError, %r{unknown item type})
    end
  end

  describe '.audiences' do
    it 'takes the names as strings too' do
      expect(Class.new(tool) { audiences 'human_agents' }.audience?(AI::Harness::Audience::HUMAN_AGENTS)).to be(true)
    end
  end

  describe 'the declarations of the MCP projection' do
    it 'gives every surface the shared description, followed by its own sentences where the tool has them' do
      expect(tool.description_for(:mcp)).to eq('Look up a printer by its name.')

      tool.description 'Look up a printer by its name.', harness: 'Without one, the printer of this conversation.', mcp: 'Each row links to it.'

      expect(tool.description_for(:mcp)).to eq('Look up a printer by its name. Each row links to it.')
      expect(tool.description_for(:harness)).to eq('Look up a printer by its name. Without one, the printer of this conversation.')
      expect(tool.definition.description).to eq('Look up a printer by its name. Without one, the printer of this conversation.')
    end

    it 'keeps a title and an output schema for MCP clients' do
      tool.title 'Look up printer'
      tool.output_schema({ type: 'object', properties: { name: { type: 'string' } } })

      expect(tool.tool_title).to eq('Look up printer')
      expect(tool.tool_output_schema).to eq('type' => 'object', 'properties' => { 'name' => { 'type' => 'string' } })
    end
  end

  describe '.declaration_errors' do
    it 'is empty for a tool that declares everything' do
      expect(tool.declaration_errors).to be_empty
      expect(tool).to be_declared
    end

    it 'names everything a tool left out' do
      expect(Class.new(described_class).declaration_errors)
        .to eq(['no description', 'no effect', 'no permission', 'not offered anywhere', 'no audience'])
    end

    it 'rejects an unknown effect, surface and audience' do
      broken = Class.new(tool) do
        effect     :delete
        offered_in :slack
        audiences  :customers
      end

      expect(broken.declaration_errors).to eq(['no effect', 'not offered anywhere', 'an unknown audience'])
    end

    it 'rejects a description for a surface the tool is not offered in' do
      harness_only = Class.new(tool) do
        description 'Look up a printer by its name.', mcp: 'Each row links to it.'
        offered_in  :harness
      end

      expect(harness_only.declaration_errors).to eq(['a description for a surface it is not offered in'])
    end
  end

  describe '.needs_run' do
    let(:running) { Class.new(tool) { needs_run } }

    it 'is declared by the tools that need the run only' do
      expect(running).to be_needs_run
      expect(tool).not_to be_needs_run
      expect(Service::AI::Tool::GetTicket).not_to be_needs_run
    end

    it 'refuses to build the tool without a run', :aggregate_failures do
      expect { running.new(arguments: { 'name' => 'Laser' }) }.to raise_error(described_class::NoRunError)
      expect(tool.new(arguments: { 'name' => 'Laser' }).run).to be_nil
    end
  end

  describe '.searches' do
    it 'marks the tools that search, whose instructions come with them' do
      expect([Service::AI::Tool::SearchTickets, Service::AI::Tool::SearchKnowledgeBase]).to all(be_search)
      expect(tool).not_to be_search
    end
  end

  describe '.loads' do
    let(:group)  { create(:group) }
    let(:agent)  { create(:agent, groups: [group]) }
    let(:ticket) { create(:ticket, group:, title: 'Printer on fire') }

    let(:tool) do
      stub_const('Service::AI::Tool::ReadTicketTitle', Class.new(described_class) do
        description 'Read the title of the ticket.'
        effect      :read
        permission  'ticket.agent'
        offered_in  :harness
        audiences   :human_agents

        loads :ticket, type: Ticket

        def execute
          { title: ticket.title }
        end
      end)
    end

    it 'loads the starting object before the tool runs, as the current user' do
      expect(tool.with_current_user(agent).execute(arguments: {}, context_object: Gql::ZammadSchema.id_from_object(ticket)))
        .to eq(title: 'Printer on fire')
    end

    it 'checks the starting object with the declared policy method' do
      customer = create(:agent_and_customer)
      ticket   = create(:ticket, customer:)
      gid      = Gql::ZammadSchema.id_from_object(ticket)

      expect(tool.with_current_user(customer).execute(arguments: {}, context_object: gid)).to eq(title: ticket.title)

      tool.loads :ticket, type: Ticket, pundit_method: :agent_read_access?
      expect { tool.with_current_user(customer).execute(arguments: {}, context_object: gid) }.to raise_error(Exceptions::Forbidden)
    end

    it_behaves_like 'an AI tool loading its object' do
      let(:user)              { agent }
      let(:readable_object)   { ticket }
      let(:unreadable_object) { create(:ticket) }
    end
  end

  describe '.loads with an object the caller names' do
    let(:group)   { create(:group) }
    let(:agent)   { create(:agent, groups: [group]) }
    let(:ticket)  { create(:ticket, group:, title: 'Printer on fire') }
    let(:other)   { create(:ticket, group:, title: 'Toner empty') }
    let(:locator) { Service::AI::Tool::Locator::Ticket }

    let(:tool) do
      stub_const('Service::AI::Tool::ReadNamedTicketTitle', Class.new(described_class) do
        description 'Read the title of a ticket.'
        effect      :read
        permission  'ticket.agent'
        offered_in  :harness, :mcp
        audiences   :human_agents

        loads :ticket, type: Ticket, pundit_method: :agent_read_access?, named: true

        def execute
          { title: ticket.title }
        end
      end)
    end

    def tool_call(arguments)
      AI::Provider::Completion::ToolCall.new(id: 'call_1', name: tool.tool_name, arguments:)
    end

    def perform_over_mcp(arguments, user: agent)
      token = create(:token, user:, preferences: { permission: %w[ticket.agent] })

      Service::AI::Tool::Runtime::PerformCall.execute(user:, tool_call: tool_call(arguments), surface: :mcp, token:)
    end

    def link_to(ticket)
      "#{Setting.get('http_type')}://#{Setting.get('fqdn')}/#ticket/zoom/#{ticket.id}"
    end

    it 'takes the ticket\'s number, ID and link as parameters, on both surfaces' do
      expect(tool.input_schema[:properties].keys).to eq(%w[ticket_number ticket_id ticket_url])
      expect(tool.declaration_errors).to be_empty
    end

    it 'cannot be declared for an object that has no locator' do
      expect { Class.new(described_class) { loads :answer, type: KnowledgeBase::Answer, named: true } }
        .to raise_error(ArgumentError, 'an object of type KnowledgeBase::Answer cannot be named')
    end

    it 'needs a name in the harness too for an object that is no starting object' do
      named_only = Class.new(described_class) { loads :user, type: User, named: true, starting: false }

      expect(named_only.argument_errors({}, surface: :harness)).to eq([Service::AI::Tool::Locator::User::NO_NAME])
      expect { Class.new(described_class) { loads :user, type: User, starting: false } }
        .to raise_error(ArgumentError, 'an object that is no starting object has to be named')
    end

    context 'when the call comes over MCP' do
      it 'reads the ticket named by its number, its ID or a link' do
        [{ ticket_number: ticket.number }, { ticket_id: ticket.id }, { ticket_url: link_to(ticket) }].each do |arguments|
          expect(perform_over_mcp(arguments).content).to eq(title: 'Printer on fire')
        end
      end

      it 'needs a name, and a link that names a ticket of this Zammad' do
        expect(perform_over_mcp({}).content).to eq(error: 'invalid_arguments', message: locator::NO_NAME)
        expect(perform_over_mcp({ ticket_url: 'https://other.example.com/#ticket/zoom/1' }).content).to eq(error: 'invalid_arguments', message: locator::NO_LINK)
        expect(tool.argument_errors({}, surface: :mcp)).to eq([locator::NO_NAME])
        expect(tool.argument_errors({}, surface: :harness)).to be_empty
      end

      it 'answers a ticket the user sees only as its customer as not found' do
        user  = create(:agent_and_customer)
        owned = create(:ticket, customer: user)

        expect(perform_over_mcp({ ticket_id: owned.id }, user:).content).to eq(error: 'not_found', message: described_class::NOT_FOUND_MESSAGE)
      end

      it_behaves_like 'an AI tool loading a named ticket' do
        let(:user)              { agent }
        let(:readable_object)   { ticket }
        let(:unreadable_object) { create(:ticket) }
      end
    end
  end

  describe '.parameter with an object to load' do
    let(:reader)   { create(:user, roles: [create(:role, permission_names: %w[ticket.agent])]) }
    let(:answer)   { create(:knowledge_base_answer, :published, translation_attributes: { title: 'Outlook sync after an update' }) }
    let(:internal) { create(:knowledge_base_answer, :internal) }

    let(:tool) do
      stub_const('Service::AI::Tool::ReadAnswer', Class.new(described_class) do
        description 'Read a knowledge base answer.'
        effect      :read
        permission  'ticket.agent'
        offered_in  :harness
        audiences   :human_agents

        parameter :answer_id, type: :integer, description: 'The answer.', required: true, loads: KnowledgeBase::Answer

        def execute
          { title: answer.translations.first.title }
        end
      end)
    end

    def perform(answer_id)
      tool_call = AI::Provider::Completion::ToolCall.new(id: 'call_1', name: tool.tool_name, arguments: { answer_id: })

      Service::AI::Tool::Runtime::PerformCall.execute(surface: :harness, user: reader, tool_call:, audience: AI::Harness::Audience::HUMAN_AGENTS)
    end

    it 'loads the object named by the argument before the tool runs, checked with its policy' do
      expect(perform(answer.id).content).to eq(title: 'Outlook sync after an update')
    end

    it 'answers an object the user may not see, and one that does not exist, as not found' do
      not_found = { error: 'not_found', message: described_class::NOT_FOUND_MESSAGE }

      expect(perform(internal.id).content).to eq(not_found)
      expect(perform(0).content).to eq(not_found)
    end

    it 'leaves the object out of the definition the model gets' do
      expect(tool.input_schema[:properties]).to eq('answer_id' => { type: 'integer', description: 'The answer.' })
    end

    it 'takes an object only by an integer ID' do
      expect { Class.new(described_class) { parameter :answer, type: :string, description: 'The answer.', loads: KnowledgeBase::Answer } }
        .to raise_error(ArgumentError, 'an object is loaded by an integer ID: answer')
    end
  end

  describe '#field_visible?' do
    let(:reader)      { create(:user, roles: [create(:role, permission_names: %w[ticket.agent])]) }
    let(:translation) { create(:knowledge_base_answer, :published, translation_attributes: { title: 'Outlook sync after an update' }).translations.first }

    let(:tool) do
      stub_const('Service::AI::Tool::ShowAnswer', Class.new(described_class) do
        description 'Show a knowledge base answer.'
        effect      :read
        permission  'ticket.agent'
        offered_in  :harness
        audiences   :human_agents

        parameter :translation_id, type: :integer, description: 'The translation.', required: true
        parameter :fields, type: :array, description: 'The fields to check.', items: { type: 'string' }

        def execute
          translation = KnowledgeBase::Answer::Translation.find(argument(:translation_id))

          argument(:fields).index_with { |field| field_visible?(translation, field) }
        end
      end)
    end

    def visible_fields(user, *fields)
      tool.with_current_user(user).execute(arguments: { 'translation_id' => translation.id, 'fields' => fields })
    end

    it 'allows every field where the policy answers true' do
      editor = create(:user, roles: [create(:role, permission_names: %w[ticket.agent knowledge_base.editor])])

      expect(visible_fields(editor, 'title', 'edited_at')).to eq('title' => true, 'edited_at' => true)
    end

    it 'follows the field scope of the policy, field by field' do
      expect(visible_fields(reader, 'title', 'edited_at', 'updated_by')).to eq('title' => true, 'edited_at' => false, 'updated_by' => false)
    end

    it 'allows no field of a record the user may not see' do
      translation.answer.update!(published_at: nil, internal_at: 1.week.ago)

      expect(visible_fields(reader, 'title')).to eq('title' => false)
    end

    it 'asks the policy once per record' do
      allow(Pundit).to receive(:policy).and_call_original
      visible_fields(reader, 'title', 'edited_at', 'updated_by')

      expect(Pundit).to have_received(:policy).with(reader, translation).once
    end
  end

  describe 'the guard against fields a field scope denies' do
    include AIToolFieldScopeHelper

    let(:reader)      { create(:user, roles: [create(:role, permission_names: %w[ticket.agent])]) }
    let(:translation) { create(:knowledge_base_answer, :published).translations.first }

    def answer_tool(checked:)
      Class.new(described_class) do
        description 'Show a knowledge base answer.'
        effect      :read
        permission  'ticket.agent'
        offered_in  :harness
        audiences   :human_agents

        parameter :translation_id, type: :integer, description: 'The translation.', required: true

        define_method(:execute) do
          translation = KnowledgeBase::Answer::Translation.find(argument(:translation_id))
          edited_at   = translation.edited_at if !checked || field_visible?(translation, :edited_at)

          { answers: [Service::AI::Tool::Output::KnowledgeBaseAnswer.row(translation, content: { edited_at: }.compact).content] }
        end
      end
    end

    def run(tool)
      Service::AI::Tool::Runtime::Result.from(tool.with_current_user(reader).execute(arguments: { 'translation_id' => translation.id }))
    end

    it 'finds a field the reader may not see' do
      expect(denied_fields_in(run(answer_tool(checked: false)).content, reader:))
        .to eq(["KnowledgeBase::Answer #{translation.answer_id}: edited_at"])
    end

    it 'finds none where the tool asked the policy' do
      expect(denied_fields_in(run(answer_tool(checked: true)).content, reader:)).to be_empty
    end

    it_behaves_like 'an AI tool returning only the fields the reader may see' do
      let(:tool_result) { run(answer_tool(checked: true)) }
    end
  end

  describe '#execute' do
    let(:agent) { create(:agent) }

    it 'runs as the current user, with a new object for every call' do
      first  = tool.with_current_user(agent).execute(arguments: { 'name' => 'Laser' })
      second = tool.with_current_user(agent).execute(arguments: { 'name' => 'Laser' })

      expect(first).to include(user_id: agent.id, arguments: { 'name' => 'Laser' })
      expect(first[:object_id]).not_to eq(second[:object_id])
    end

    it 'refuses to run without a current user' do
      expect { tool.execute(arguments: {}) }.to raise_error(RuntimeError, %r{Current user is required})
    end
  end
end
