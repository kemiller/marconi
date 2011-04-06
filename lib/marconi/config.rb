
module Marconi
  class Config
    attr_accessor :name, :short_name, :keepalive, :bunny_params, :listeners
    def initialize
      config_file = "#{Rails.root}/config/queues.yml"

      unless File.exists?(config_file)
        raise "Could not find #{config_file}"
      end

      params = YAML.load_file(config_file)

      self.name = params['name'] || raise("Wait... Who am I?")
      self.short_name = params['short_name'] || raise("w8... hu m i?")
      self.keepalive = !!params['keepalive']
      self.listeners = params['listeners'] || []
      self.bunny_params = params['bunny'] && params['bunny'][Rails.env]

      unless bunny_params
        puts "Warning: No config specified for #{Rails.env}"
        self.bunny_params = {}
      end

    end
  end
end
