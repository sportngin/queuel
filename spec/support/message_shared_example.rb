shared_examples "a message" do
  let(:id) { 1 }
  let(:body) { "test" }
  let(:queue) { nil }
  let(:message_object) { double "wrapped message" }
  subject { described_class.new message_object }

  it { should respond_to :id }
  it { should respond_to :body }
  it { should respond_to :queue }
end
