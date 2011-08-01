
require 'active_support/core_ext/hash/indifferent_access'

module Marconi
  module Receiver

    def self.included(base)
      base.extend ClassMethods
      base.setup
    end

    module ClassMethods
      
      def setup
        @master_model_name = self.name.underscore
      end

      def master_model_name
        @master_model_name
      end

      def register(operation, &block)
        self.handlers[operation] ||= []
        self.handlers[operation] << block
      end

      def handlers
        @handlers ||= HashWithIndifferentAccess.new
      end

      def log_message_action(amqp_mesg, info_mesg)
        fmt = "%28s %9s %s %s" %
          [amqp_mesg[:meta][:guid],
           amqp_mesg[:meta][:operation],
           Time.now().to_s, info_mesg]
        logger.debug(fmt)
        Marconi.log(fmt)
      end

      def listen(max = nil)
        q_name = "#{Marconi.application_name}.#{self.master_model_name}"
        topic = "#.#{self.master_model_name}.#"
        exchange.subscribe(q_name, :key => topic, :message_max => max) do |amqp_msg|
          e = Envelope.from_xml(amqp_msg[:payload])
          suppress_broadcasts do
            e.messages.each do |message|
              log_message_action(message, "Receiving")
              operation = message[:meta][:operation]
              next unless self.handlers[operation]
              self.handlers[operation].each do |h|
                h.call(message)
              end
            end
          end
        end
      end

      def suppress_broadcasts
        @suppress_broadcasts = true
        yield
      ensure
        @suppress_broadcasts = false
      end

      def broadcasts_suppressed?
        @suppress_broadcasts
      end

      def purge_handlers
        @handlers = nil
      end

      def exchange 
        Marconi.outbound
      end
    end

    def log_message_action(amqp_mesg, info_mesg)
      self.class.log_message_action(amqp_mesg, info_mesg)
    end

  end

end
