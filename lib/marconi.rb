
module Marconi

  extend self

  attr_accessor :backup_queue_class_name, :logger

  # this uses eval to get the class from its name because
  # otherwise rails class reloading in dev will screw everything up
  def backup_queue_class
    eval(backup_queue_class_name)
  end

  def inbound
    @inbound ||= exchange('marconi.events.inbound')
  end

  def outbound
    @outbound ||= exchange('marconi.events.outbound')
  end

  def error
    @error ||= exchange('marconi.events.error')
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

  def log(message)
    logger.info(message) if logger
  end

end

require 'marconi/exchange'
require 'marconi/config'
require 'marconi/envelope'
require 'marconi/receiver'
require 'marconi/broadcaster'
