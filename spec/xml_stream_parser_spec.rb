#!/usr/bin/env spec

require 'rubygems'
require 'spec'
require File.expand_path( File.join( File.dirname(__FILE__) , ".." , "lib", "xml_stream_parser" ) )

describe XmlStreamParser do
  it "should parse a simple one element document" do
    XmlStreamParser.new.parse( "<foo></foo>" ) do |p|
      called = false
      p.consume_element("foo") { |name,attrs|
        called = true
        name.should ==("foo")
        attrs.should ==({})
      }
      called.should ==(true)
    end
  end
  
  describe "find_element" do
    
    it "should skip whitespace" do
      XmlStreamParser.new.parse( "   \n\n\n<foo></foo>") do |p|
        name = p.find_element("foo")
        name.should ==("foo")
        e = p.pull_parser.pull
        e.start_element?.should ==(true)
        e[0].should == "foo"
        e[1].should == {}
      end
    end

    it "should throw on unexpected elements" do
      XmlStreamParser.new.parse( "<foo></foo>") do |p|
        lambda { 
          name = p.find_element("bar")
        }.should raise_error( RuntimeError )
      end
    end

    it "should match one of multiple elements" do
      XmlStreamParser.new.parse( "<foo></foo>" ) do |p|
        name = p.find_element( ["bar","foo" ] )
        name.should ==( "foo" )
      end
    end

    it "should skip ignored elements" do
      XmlStreamParser.new.parse( "<foo></foo><bar></bar>" ) do |p|
        name = p.find_element( "bar", "foo" )
        name.should ==( "bar" )
      end
    end

    it "should skip ignored elements even containing a non-ignored element" do
      XmlStreamParser.new.parse( '<foo>random <bar b="1"> text</bar></foo><bar b="2"></bar>' ) do |p|
        name = p.find_element( "bar", "foo" )
        name.should ==( "bar" )
        e = p.pull_parser.pull
        e[0].should ==("bar")
        e[1].should ==( { "b"=>"2" } )
      end
    end

  end

end
