
require 'test/unit'
require 'shoulda'
require 'mocha'
require 'active_record'
require 'marconi'
require 'marconi/guid_generator'
require 'fake_ar'

Marconi.init(File.join(File.dirname(__FILE__),'fixtures','queues.yml'), 'test')

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

