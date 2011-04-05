module Q
  class Error
    include Q::Generic
    ERROR_EXCHANGE_NAME = 'error'
    def self.exchange_name
      ERROR_EXCHANGE_NAME
    end
  end
end
