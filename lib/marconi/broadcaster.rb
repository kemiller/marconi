
require 'active_support/core_ext/string/inflections'

module Marconi
  module Broadcaster

    def self.included(base)
      base.extend ClassMethods
      base.setup
    end

    module ClassMethods
      def setup
        @master_model_name = self.name.underscore

        # Callbacks
        after_update :publish_update
        after_create :publish_create
        after_destroy :publish_destroy
      end

      def master_model_name
        @master_model_name
      end
    end

    def publish_update
      publish('update')
    end

    def publish_create
      publish('create')
    end

    def publish_destroy
      publish('destroy')
    end

    def publish(operation)

      # This is set in Receiver if it's included.  Intent is to 
      # prevent sending messages in response to incoming messages and thus
      # creating infinite loops.
      return if self.class.respond_to?(:broadcasts_suppressed?) &&
        self.class.broadcasts_suppressed?

      fmt = "%28s %9s %s Published" % [guid,operation,Time.now.to_s]
      logger.debug fmt
      Marconi.log(fmt)

      e = Envelope.new { |e| e.send(operation, self) }
      topic = "#{Marconi.application_name}.#{self.class.master_model_name}.#{operation}"
      exchange.publish(e.to_s, :topic => topic)
    end

    private

    def exchange
      Marconi.inbound
    end

  end
end
