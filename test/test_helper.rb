
require 'test/unit'
require 'shoulda'
require 'active_record'
require 'marconi'
require 'marconi/guid_generator'

Marconi.init(File.join(File.dirname(__FILE__),'fixtures','queues.yml'), 'test')

class HashStruct
  
  def initialize(attrs = {})
    @defaults = attrs.with_indifferent_access
  end

  def new(overrides = {})
    Klass.new(@defaults.merge(overrides))
  end

  class Klass
    def initialize(attrs = {})
      @attributes = attrs.with_indifferent_access
    end

    def attributes
      @attributes
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
  end
end

Person  = HashStruct.new(
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

