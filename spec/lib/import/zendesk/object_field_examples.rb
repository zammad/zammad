RSpec.shared_examples 'Import::Zendesk::ObjectField' do

  it 'initializes a object field backend import' do

    object_field = double(id: 31_337, title: 'Example Field')
    allow(object_field).to receive(:[]).with('key').and_return(object_field.title)

    dummy_instance = double()

    local_name    = 'example_field'
    dummy_backend = instance_double(Class)
    expect(dummy_backend).to receive(:new).with(kind_of(String), local_name, object_field).and_return(dummy_instance)
    expect_any_instance_of(described_class).to receive(:backend_class).and_return(dummy_backend)
    created_instance = described_class.new(object_field)

    expect(created_instance).to respond_to(:id)
    expect(created_instance.id).to eq(local_name)

    expect(created_instance).to respond_to(:zendesk_id)
    expect(created_instance.zendesk_id).to eq(object_field.id)
  end
end
