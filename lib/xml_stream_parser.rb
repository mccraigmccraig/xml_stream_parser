require 'stringio'
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

  class Sentinel
    def to_s
      self.class.to_s
    end
  end

  class Nothing < Sentinel
  end

  class EndContext < Sentinel
  end

  module Sentinels
    NOTHING = Nothing.new
    END_CONTEXT = EndContext.new
  end

  include Sentinels

  # the REXML::Parsers::PullParser used internally
  attr_reader :pull_parser

  def parse(data, &block)
    io = case data
         when IO
           data
         when StringIO
           data
         when String
           StringIO.new(data)
         end

    @pull_parser = REXML::Parsers::PullParser.new( io )
    block.call(self)
  ensure
    @pull_parser = nil
  end

  # find an element with name in element_names : inter-element whitespace is ignored
  # - encountering end_element terminates and returns END_CONTEXT, leaving parser on end_element
  # - encountering end_document terminates and returns END_CONTEXT
  # - encountering start_element for an element not in element_names NOTHING, parser on start_element
  # - encountering start_element for an element in element_names returns element name, parser on start_element
  def find_element( element_names )
    element_names = [ *element_names ]

    while( true )
      e = @pull_parser.peek
      if e.start_element?
        if element_names.include?( e[0] )
          return e[0]
        else
          return NOTHING
        end
      elsif e.end_element?
        return END_CONTEXT
      elsif e.end_document?
        return END_CONTEXT
      elsif e.text? 
        # ignore whitespace between elements
        raise "unexpected text content: #{e.inspect}" if e[0] !~ /[[:space:]]/
        @pull_parser.pull
      end
    end
  end

  # parse and throw away content until we escape the current context, either
  # through end_element, or end_document
  def discard()
    element_stack = []

    while(true)
      e = @pull_parser.peek
      name = e[0]
      if e.start_element?
        element_stack.push(name)
      elsif e.end_element?
        return nil if element_stack.size == 0
        raise "mismatched end_element. expected </#{element_stack.last}>, got: #{e.inspect}" if name != element_stack.last
        element_stack.pop
      elsif e.end_document?
        return nil if element_stack.size ==0
        raise "mismatched end_element. expected </#{element_stack.last}>, got: #{e.inspect}"
      end
      @pull_parser.pull
    end
  end

  # consume an element
  # - if optional is false the element must be present
  # - if optional is true and the element is not present then NOTHING/END_CONTEXT
  #   will be returned
  # - consumes start_element, calls block on content, consumes end_element
  def element( element_names, optional=false, &block )
    element_names = [ *element_names ]

    f = find_element(element_names)
    e = @pull_parser.peek

    if f.is_a? Sentinel
      if optional
        return f
      else
        raise "expected start element: <#{element_names.join('|')}, got: #{e.inspect}>"
      end
    end

    e = @pull_parser.pull # consume the start tag
    name = e[0]
    attrs = e[1]
    
    # block should consume all element content, and leave parser on end_element, or
    # whitespace before it
    err=false
    begin
      v = block.call(name, attrs)
      return v if ! v.is_a? Sentinel # do not propagate Sentinels. they confuse callers
    rescue
      err=true  # note that we are erroring, so as not to mask the exception from ensure block
      raise
    ensure  
      if !err # if return was called in the block, ensure we consume the end_element
        e = @pull_parser.pull
        e = @pull_parser.pull if e.text? && e[0] =~ /[[:space:]]/
        raise "expected end tag: #{name}, got: #{e.inspect}" if ! e.end_element? || e[0] != name
      end
    end
  end

  # find and consume elements, calling block on each one found
  # return result of last find : NOTHING or END_CONTEXT sentinel
  def elements( element_names, &block )
    while true
      break if element(element_names, true, &block).is_a? Sentinel
    end

    return nil
  end

  # consume text element
  # returns the text, or nil if none
  def text( &block )
    e = @pull_parser.peek
    raise "expected text node, got #{e.inspect}" if ! e.text? && ! e.end_element?
    text = if e.text?
             @pull_parser.pull
             e[0]
           else
             nil
           end
    block.call( text ) if block
    text
  end

end

