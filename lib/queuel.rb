require "queuel/version"
require "forwardable"
require "queuel/base_klass"

require "queuel/base/engine"
require "queuel/base/queue"
require "queuel/base/message"
require "queuel/base/poller"

require "queuel/null/engine"
require "queuel/null/queue"
require "queuel/null/message"
require "queuel/null/poller"

require "queuel/iron_mq/engine"
require "queuel/iron_mq/queue"
require "queuel/iron_mq/message"
require "queuel/iron_mq/poller"

require "queuel/client"

module Queuel
  class << self
    extend Forwardable
    def_delegators :client, :push, :pop, :receive, :with
    def_delegators :config, :credentials, :default_queue
    alias << pop
  end

  def self.engine
    requires
    Object.module_eval("::#{const_name}", __FILE__, __LINE__)
  end

  def self.configure(&block)
    config.instance_eval &block
  end

  def self.config
    @config ||= Configurator.new
  end

  def self.client
    Client.new engine, credentials
  end

  def self.engines
    {
      iron_mq: { require: 'iron_mq', const: "IronMq" },
      null: { const: "Null" }
    }
  end

  def self.requires
    require engines[config.engine][:require] if engines.fetch(config.engine, {})[:require]
  end

  def self.const_name
    "Queuel::#{engines.fetch(config.engine, {}).fetch(:const, nil) || engines[:null][:const]}::Engine"
  end

  class Configurator
    def self.param(*params)
      params.each do |name|
        attr_accessor name
        define_method name do |*values|
          value = values.first
          value ? self.send("#{name}=", value) : instance_variable_get("@#{name}")
        end
      end
    end

    param :credentials
    param :engine
    param :default_queue
  end
end
