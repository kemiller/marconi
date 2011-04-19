
module Marconi

  extend self

  def inbound
    Q::Inbound.instance
  end

  def outbound
    Q::Outbound.instance
  end

  def error
    Q::Error.instance
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
end

require 'marconi/q/generic'
require 'marconi/q/outbound'
require 'marconi/q/inbound'
require 'marconi/q/error'
require 'marconi/config'
require 'marconi/envelope'
require 'marconi/receiver'
require 'marconi/broadcaster'
