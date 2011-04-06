
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

  def application_name
    inbound.name
  end

  def listen
    inbound.config

    inbound.listeners.each do |class_name|
      class_name.constantize.listen
    end
  end
end

require 'marconi/q/generic'
require 'marconi/q/outbound'
require 'marconi/q/inbound'
require 'marconi/q/error'
require 'marconi/envelope'
require 'marconi/receiver'
require 'marconi/broadcaster'
