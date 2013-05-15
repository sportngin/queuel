require 'spec_helper'
describe Queuel do
  it { should respond_to :engine }
  it { should respond_to :configure }
  it { should respond_to :config }

  it { should respond_to :push }
  it { should respond_to :pop }
  it { should respond_to :<< }
  it { should respond_to :receive }

  describe "configuration" do
    before do
      subject.configure do
        credentials username: "jon"
      end
    end

    it "set the credentials" do
      subject.config.credentials.should == { username: "jon" }
    end
  end

  describe "engine" do
    describe "unset settings" do
      before { subject.instance_variable_set "@config", nil }
      its(:engine) { should == Queuel::Null::Engine }
    end

    describe "with configured" do
      before do
        subject.configure { engine :iron_mq }
      end
      after do
        subject.configure { engine nil }
      end

      its(:engine) { should == Queuel::IronMq::Engine }
    end
  end
end
