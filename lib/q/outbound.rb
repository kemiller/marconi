module Q
  class Outbound
    include Q::Generic
    OUTBOUND_EXCHANGE_NAME = 'outbound'
    def self.exchange_name
      OUTBOUND_EXCHANGE_NAME
    end
  end
end
