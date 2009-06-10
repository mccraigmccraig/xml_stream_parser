#!/usr/bin/env spec

require 'rubygems'
require 'spec'
require File.expand_path( File.join( File.dirname(__FILE__) , ".." , "lib", "xml_stream_parser" ) )

describe XmlStreamParser do
  it "should parse a simple one element document" do
    p = XmlStreamParser.new( StringIO.new("<foo></foo>") )

    called = false
    p.find_element("foo") { 
      p.consume_element("foo"){ 
        called = true
      }
    }
    called.should ==(true)
  end
  
end
