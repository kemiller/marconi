
module Marconi

  extend self

  attr_accessor :backup_queue_class

  def inbound
    @inbound ||= exchange('inbound')
  end

  def outbound
    @outbound ||= exchange('outbound')
  end

  def error
    @error ||= exchange('error')
  end

  def config
    @config ||= Config.new
  end

  def application_name
    config.name
  end

  def short_application_name
    config.short_name
  end

  def listen
    config.listeners.each do |class_name|
      fork do

        # this is to ditch any exit handlers.  Minitest in ruby 1.9
        # for some reason sets itself to run an empty suite at exit.
        at_exit { exit! }

        # Change the process name as it appears in ps/top so the proc 
        # is easy to identify
        $0 = "ruby #{$0} Marconi.listen [#{class_name}]"

        class_name.constantize.listen
      end
    end

    Process.waitall
  rescue Interrupt
    Process.kill("-INT",0) # interrupt the whole process group
  end

  def run_recovery_loop
    if backup_queue_class
      backup_queue_class.find_each do |bc|
        if exchange(bc.exchange_name).publish(bc.body, :topic => bc.topic, :recovering => true)
          bc.destroy
        end
      end
    end
  end

  def exchange(name)
    @registry ||= {}
    @registry[name] ||= Exchange.new(name)
  end
  
end

require 'marconi/exchange'
require 'marconi/config'
require 'marconi/envelope'
require 'marconi/receiver'
require 'marconi/broadcaster'
