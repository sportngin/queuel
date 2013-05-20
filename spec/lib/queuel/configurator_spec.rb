require 'spec_helper'
module Queuel
  describe Configurator do
    describe "configuration" do
      before do
        subject.credentials username: "jon"
      end

      it "set the logger" do
        subject.logger.should be_a Logger
        subject.log_level.should == MonoLogger::ERROR
      end

      describe "configured logger" do
        let(:some_other_logger) { double "logger" }

        it "fails on a logger without the correct methods" do
          expect { subject.logger some_other_logger }.to raise_error Configurator::InvalidConfigurationError,
            "Logger must respond to #{%w[info warn debug level level]}"
        end
      end

      it "set the credentials" do
        subject.credentials.should == { username: "jon" }
      end

      it "has a default worker count" do
        subject.receiver_threads.should == 1
      end
    end
  end
end
