require 'rexml/document'
require 'rexml/parsers/pullparser'

module REXML
  module Parsers
    class PullEvent
      # PullEvent is missing the end_document? method, even tho 
      # the BaseParser produces the event
      def end_document?
        @contents[0] == :end_document
      end
    end
  end
end

class XmlStreamParser

  VERSION = "0.1.0"
  
  # the REXML::Parsers::PullParser used internally
  attr_reader :parser

  # construct on an IO
  def initialize(io)
    @parser = REXML::Parsers::PullParser.new( io )
  end

  # find an element with name from element_names, and hand off to a block for processing
  # - encountering an end_element terminates and returns nil, leaving parser pointing to end_element
  # - encountering end_document terminates and returns nil
  # - block is called with parser pointing to start_element of matching element. block return value is returned (must be non-nil)
  # - the block should consume the element, leaving the parser pointing after it's end_element
  def find_element( element_names, &block )
    element_names = [ *element_names ]

    element_stack = []

    while( true )
      e = @parser.peek
      if e.start_element?
        if element_stack.size==0 && element_names.include?( e[0] )
          v = block.call # block must consume the matched element, and return some value
          raise "block must return a value for element: #{e[0]}" if ! v
          return v
        else
          element_stack.push( e[0] )
          @parser.pull
        end
      elsif e.end_element?
        if element_stack.size == 0
          return nil # returning from context, leaving parser on end element
        else
          if element_stack.last == e[0]
            element_stack.pop
            @parser.pull
          else
            raise "mismatched end element: <#{e[0]}>"
          end
        end
      elsif e.end_document?
        raise "missing end tags: #{element_stack.inspect}" if element_stack.size>0
        return nil
      elsif e.text? 
        # ignore whitespace between elements
        raise "unexpected text content: #{e.to_s}" if e[0] !~ /[[:space:]]/
          @parser.pull
      end
    end
  end

  # consume a start_element, call a block on the content, consume the end_element
  # the value of the block call is returned
  def consume_element( element_name, &block )
    e = @parser.pull
    raise "expected start tag: #{element_name}, got: #{e.inspect}" if ! e.start_element? || e[0] != element_name
    attrs = e[1]

    # block should consume all element content, and leave parser on end_element, or
    # whitespace before it
    v = block.call

    e = @parser.pull
    e = @parser.pull if e.text? && e[0] =~ /[[:space:]]/
    raise "expected end tag: #{element_name}, got: #{e.inspect}" if ! e.end_element? || e[0] != element_name

    [v, attrs]
  end

  # parser should be positioned on start_element
  # returns text, attributes_hash
  def consume_text_element( element_name )
    consume_element(element_name) do
      e = @parser.peek
      raise "expected text node, got #{e.inspect}" if ! e.text? && ! e.end_element?
      if e.text?
        @parser.pull
        e[0]
      else
        ""
      end
    end
  end


  
end
