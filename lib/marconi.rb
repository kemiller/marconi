
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
      class_name.constantize.listen
    end
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
