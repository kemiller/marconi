
require 'test/unit'
require 'shoulda'
require 'mocha'
require 'active_record'
require 'marconi'
require 'marconi/guid_generator'

Marconi.init(File.join(File.dirname(__FILE__),'fixtures','queues.yml'), 'test')

class FakeAR

  attr_reader :attributes

  def initialize(attrs = {})
    @attributes = self.class.defaults.merge(attrs)
  end

  def method_missing(method, *args)
    if @attributes.has_key?(method)
      @attributes[method]
    elsif method =~ /\A(.*)=\Z/ && @attributes.has_key?($1)
      @attributes[$1] = args.first
    else
      raise NoMethodError
    end
  end

  def logger
    self.class.logger
  end

  class << self

    def set_defaults(hash)
      @defaults = hash.with_indifferent_access
    end

    def defaults
      @defaults ||= {}
    end

    def after_update(*methods)
      @after_update = methods
    end

    def after_create(*methods)
      @after_create = methods
    end

    def after_destroy(*methods)
      @after_destroy = methods
    end

    def logger
      @logger ||= begin
                    l = Logger.new(STDOUT)
                    l.level = Logger::ERROR
                    l
                  end
    end

    def create!(*args)
      new(*args)
    end

  end

end

class UnsentMessage < FakeAR
  set_defaults(:exchange_name => nil, :topic => nil, :body => nil)
end

Marconi.backup_queue_class_name = 'UnsentMessage'

class Person < FakeAR

  include Marconi::Broadcaster
  include Marconi::Receiver

  set_defaults(
    :guid => Marconi::GUIDGenerator.next_guid,
    :segment => "FOO",
    :subsegment => "BAR",
    :status => "new",
    :email => "test@example.com",
    :first_name => "Marky",
    :last_name => "Mark",
    :crypted_password => "adsfasdfasfasdf",
    :password_salt => "asdfasdfasdf",
    :version => 0
  )

end


class Test::Unit::TestCase
  
  def assert_soft_equal(expected, actual)
    assert_equal normalize_value(expected), normalize_value(actual)
  end

  def normalize_value(val)
    case val
      when Array; val.map { |elt| normalize_value(elt) }
      when Hash
        h = HashWithIndifferentAccess.new
        val.each { |key, value| h[normalize_value(key)] = normalize_value(value) }
        h
      when Symbol,Date; val.to_s
      when Time,DateTime; val.utc.to_s(:db)
      else; val
    end
  end
  
end

