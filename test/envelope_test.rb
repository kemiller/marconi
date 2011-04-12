
require 'test_helper'

class EnvelopeTest < ActiveSupport::TestCase

  should "create an envelope with a topic" do
    e = Marconi::Envelope.new(:timestamp => @seed_time, :topic => "foo")
    assert_equal "foo", e.topic
  end

  context "adding messages" do
    setup do
      @seed_time = Time.now.utc
      @person = Factory(:person)
      @template_message = {
        :meta => { :operation => nil, :guid => @person.guid, :version => @person.version, :timestamp => @seed_time },
        :data => HashWithIndifferentAccess.new(@person.attributes)
      }
    end

    should "allow adding a create message" do
      e = Marconi::Envelope.new(:timestamp => @seed_time, :timestamp => @seed_time)
      e.create @person
      @template_message[:meta][:operation] = 'create'
      assert_equal [@template_message], e.messages
    end

    should "allow adding an update message" do
      e = Marconi::Envelope.new(:timestamp => @seed_time, :timestamp => @seed_time)
      e.update @person
      @template_message[:meta][:operation] = 'update'
      assert_equal [@template_message], e.messages
    end

    should "allow adding an override message" do
      overridden_guid = "sd-0000000000000000000000123"
      e = Marconi::Envelope.new(:timestamp => @seed_time, :timestamp => @seed_time)
      e.override overridden_guid, @person
      @template_message[:meta][:operation] = 'override'
      @template_message[:meta][:guid] = overridden_guid
      assert_equal [@template_message], e.messages
    end

    should "preserve order of messages" do
      e = Marconi::Envelope.new(:timestamp => @seed_time, :timestamp => @seed_time)
      e.create @person
      e.update @person
      first = @template_message.dup; first[:meta] = first[:meta].dup
      second = @template_message.dup; second[:meta] = second[:meta].dup
      first[:meta][:operation] = 'create'
      second[:meta][:operation] = 'update'
      assert_equal [first, second], e.messages
    end

    should "construct total contents" do
      e = Marconi::Envelope.new(:timestamp => @seed_time, :topic => "idauth.person.create")
      e.create @person
      @template_message[:meta][:operation] = 'create'
      assert_equal({ :headers => { :topic => "idauth.person.create" }, :payload => [@template_message] }, e.contents)
    end

    should "allow construction using a block" do
      e = Marconi::Envelope.new(:timestamp => @seed_time, :topic => "idauth.person.create") do |e|
        e.create @person
      end
      @template_message[:meta][:operation] = 'create'
      assert_equal({ :headers => { :topic => "idauth.person.create" }, :payload => [@template_message] }, e.contents)
    end

    should "serialize an Marconi::Envelope" do
      e = Marconi::Envelope.new(:timestamp => @seed_time, :topic => "idauth.person.create")
      e.create @person
      e.update @person
      first = @template_message.dup; first[:meta] = first[:meta].dup
      second = @template_message.dup; second[:meta] = second[:meta].dup
      first[:meta][:operation] = 'create'
      second[:meta][:operation] = 'update'
      serialized = { :headers => { :topic => "idauth.person.create" }, :payload => [first, second] }.to_xml
      assert_equal serialized, e.to_s
    end
    
    should "parse a JSON string" do
      payload = @template_message
      payload[:meta][:operation] = 'create'
      message_hash = { :headers => { :topic => "idauth.person.create" },
        :payload => [payload] }
      message_xml = message_hash.to_xml
      Marconi::Envelope = Marconi::Envelope.from_xml(message_xml)
      assert_equal 'idauth.person.create', Marconi::Envelope.topic
      assert_soft_equal([payload], Marconi::Envelope.messages)
    end
    
  end


end
