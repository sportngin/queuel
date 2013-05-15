shared_examples "an engine" do
  let(:client_object) { double "Client Object" }
  let(:client) { double "#{described_class.name} Client", new: client_object }
  let(:queue_const) { Object.module_eval("#{described_class.to_s.split("::")[0..-2].join("::")}::Queue",__FILE__,__LINE__) }

  before do
    subject.stub client_klass: client
  end

  it { should respond_to :queue }

  it "can grab a queue" do
    subject.queue("some_queue").should be_a queue_const
  end
end
