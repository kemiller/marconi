module Q
  class Inbound
    include Q::Generic
    INBOUND_EXCHANGE_NAME = 'inbound'
    def self.exchange_name
      INBOUND_EXCHANGE_NAME
    end
  end
end
