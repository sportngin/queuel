module IntegrationHelpers
  def config
    @@config ||= YAML::load_file(File.expand_path('../../integration.yml', __FILE__))
  end

  def client
    @client ||= begin
      c = config
      creds = Hash[*c['credentials'].map {|k, v| [k.to_sym, v]}.flatten]
      Queuel.configure do
        engine c['engine'].to_s.to_sym
        credentials creds
      end
      Queuel.with(c['queue'])
    end
  end

  def queue
    @queue = client.send :queue_connection
  end
end
