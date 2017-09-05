shared_examples "a message" do
  let(:id) { 1 }
  let(:body) { "test" }
  let(:queue) { nil }
  let(:message_object) { double "wrapped message" }
  let(:options) { {} }
  subject { described_class.new message_object, options }

  it { should respond_to :id }
  it { should respond_to :body }
  it { should respond_to :queue }
  it { should respond_to :attributes }

  describe 'with :attributes in the constructor options' do
    let(:options) { { attributes: { foo: 1, bar: 2} } }

    it 'sets message attributes' do
      expect(subject.attributes).to include(options[:attributes])
    end
  end
end
