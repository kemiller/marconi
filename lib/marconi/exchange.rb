require 'bunny'

module Marconi
  class Exchange

    def initialize(exchange_name)
      @exchange_name = exchange_name
    end

    def exchange_name
      @exchange_name
    end

    def name
      Marconi.config.name
    end

    def keepalive
      Marconi.config.keepalive
    end

    def bunny_params
      Marconi.config.bunny_params
    end

    DEFAULT_PUBLISH_OPTIONS = {
      # Tells the server how to react if the message cannot be routed to a queue.
      # If set to true, the server will return an unroutable message with a Return method.
      # If set to false, the server silently drops the message.
      :mandatory => true,

      # Tells the server how to react if the message cannot be routed to a
      # queue consumer immediately.  If set to true, the server will return an
      # undeliverable message with a Return method.  If set to false, the
      # server will queue the message, but with no guarantee that it will ever
      # be consumed.
      :immediate => false,

      # Tells the server whether to persist the message.  If set to true, the
      # message will be persisted to disk and not lost if the server restarts.
      # Setting to true incurs a performance penalty as there is an extra cost
      # associated with disk access.
      :persistent => true
    }

    # Example: Marconi.inbound.publish("Howdy!", :topic => 'deals.member.create')
    def publish(msg, options = {})
      topic = ensure_valid_publish_topic(options)
      begin
        connect
        @exchange.publish(msg, DEFAULT_PUBLISH_OPTIONS.merge(:key => topic))
        retmsg = @bunny.returned_message
        raise "Invalid return payload" unless retmsg[:payload] == :no_return
        true
      rescue Exception => e
        Marconi.log(e)
        if Marconi.backup_queue_class && !options[:recovering]
          Marconi.backup_queue_class.create!(:exchange_name => exchange_name,
                                             :topic => topic,
                                             :body => msg)
        end
        false
      end
    end

    # Example: Marconi.inbound.subscribe('foo_q', :key => 'deals.member.*') { |msg| puts msg[:payload] }
    def subscribe(q_name, options = {}, &block)
      q, key = get_q(q_name, options)
      q.subscribe(options, &block)
    end

    # Example: Marconi.inbound.pop('foo_q', :key => 'deals.member.*')
    def pop(q_name, options = {})
      q, key = get_q(q_name, options)
      msg = q.pop[:payload]
      msg == :queue_empty ? nil : msg
    end

    unless Rails.env.production? # HARD CORE
      # Example: Marconi.inbound.purge_q('foo_q')
      # Use judiciously - this tosses all messages in the Q!
      def purge_q(q_name)
        connect
        unless q_name.blank?
          if o = exists?(:queue, q_name)
            o.purge
          end
        end
      rescue Bunny::ForcedChannelCloseError
        connect(true) # Connection is fucked after this error, so it must be refreshed
        raise
      end

      # Example: Marconi.inbound.nuke_q('foo_q')
      # Use judiciously - this tosses all messages in the Q *and* nukes it
      def nuke_q(q_name)
        generic_nuke(:queue, q_name) 
      end
    end

    private

    def connected?
      @bunny && @bunny.status == :connected && @exchange
    end

    def connect(reconnect = false)
      reconnect = true unless keepalive
      @bunny.stop if reconnect && connected? rescue nil
      if reconnect || !connected?
        @bunny = Bunny.new(bunny_params)
        result = @bunny.start
        if result == :connected
          @exchange =
            @bunny.exchange(
              exchange_name,

              # Topic queues are broadcast queues that allow wildcard subscriptions
              :type => :topic,

              # Durable exchanges remain active when a server restarts.
              # Non-durable exchanges (transient exchanges) are purged if/when
              # a server restarts.
              :durable => true
            )
          result
        else
          raise "Unable to connect to RabbitMQ: #{result}"
        end
      end
    rescue Bunny::ProtocolError # raised by @bunny.start
      @bunny = nil
      raise
    end

    def ensure_valid_publish_topic(options)
      raise "You must specify a topic to publish to!" unless topic = options[:topic]
      raise "You may not publish to a topic name with a wildcard" if topic =~ /[*#]/
      topic
    end

    DEFAULT_Q_OPTIONS = {
      :durable => true,
      :exclusive => false,
      :auto_delete => false
    }

    def get_q(q_name, options)
      connect
      raise "You must specify a topic to subscribe to!" unless key = options[:key]
      raise "You must specify a Queue Name" if q_name.blank?
      q = @bunny.queue(q_name, DEFAULT_Q_OPTIONS)
      q.bind(@exchange, :key => key)
      [q, key]
    rescue Bunny::ForcedChannelCloseError, Bunny::ProtocolError
      connect(true) # Connection is fucked after this error, so it must be refreshed
      raise
    end

    def exists?(type, name)
      @bunny.send(type, name, :passive => true)
      # Annoyingly, this error is thrown if the q or exchange can't be found ... yet :passive isn't
      #  supposed to err!!  Bah.
    rescue Bunny::ForcedChannelCloseError
      connect(true) # Connection is fucked after this error, so it must be refreshed
      nil
    end

    def generic_nuke(type, name)
      connect
      unless name.blank?
        if o = exists?(type, name)
          o.delete
        end
      end
    rescue Bunny::ForcedChannelCloseError
      connect(true) # Connection is fucked after this error, so it must be refreshed
      raise
    end
  end
end
