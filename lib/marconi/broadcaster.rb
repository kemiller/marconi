
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
        after_save :publish
      end

      def master_model_name
        @master_model_name
      end
    end

    def publish

      # This is set in Receiver if it's included.  Intent is to 
      # prevent sending messages in response to incoming messages and thus
      # creating infinite loops.
      return if self.class.respond_to?(:broadcasts_suppressed?) &&
        self.class.broadcasts_suppressed?

      fmt = "%28s %9s %s Published" % [guid,current_operation,Time.now.to_s]
      logger.debug fmt
      puts fmt unless Rails.env.test?

      e = Envelope.new { |e| e.send(current_operation, self) }
      topic = "#{Rails.application_name}.#{self.class.master_model_name}.#{current_operation}"
      Marconi.inbound.publish(e, :topic => topic)
    end

    private

    def current_operation
      id_changed? ? 'create' : 'update'
    end
  end
end
