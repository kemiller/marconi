
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
end

require 'marconi/q/generic'
require 'marconi/q/outbound'
require 'marconi/q/inbound'
require 'marconi/q/error'
require 'marconi/envelope'
require 'marconi/receiver'
require 'marconi/broadcaster'
