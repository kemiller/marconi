

module Marconi
  class Envelope

    attr_accessor :topic

    class << self

      def from_xml(xml)
        return nil unless xml
        Envelope.new(:xml => xml)
      end

    end

    def initialize(options = {}, &block)
      if xml = options[:xml]
        hash = SmartXML.parse(xml)
        @topic = hash[:headers][:topic]
        hash[:payload].each do |hsh|
          messages << { :meta => hsh[:meta], :data => HashWithIndifferentAccess.new(hsh[:data]) }
        end
      else
        @timestamp = options[:timestamp] || Time.now
        @topic = options[:topic]
        block.call(self) if block_given?
      end
    end

    def messages
      @messages ||= []
    end

    def contents
      { :headers => headers, :payload => messages }
    end

    def create(model)
      add_message(model, :create)
    end

    def update(model)
      add_message(model, :update)
    end

    def destroy(model)
      add_message(model, :destroy)
    end

    def override(old_guid, model)
      add_message(model, :override, old_guid)
    end

    def to_s
      contents.to_xml
    end

    private

    def headers
      { :topic => @topic }
    end

    def add_message(model, operation, guid = model.guid)
      meta = {
        :operation => operation.to_s,
        :guid => guid,
        :version => model.version,
        :timestamp => @timestamp
      }
      messages << { :meta => meta, :data => HashWithIndifferentAccess.new(model.attributes) }
    end

  end
end
