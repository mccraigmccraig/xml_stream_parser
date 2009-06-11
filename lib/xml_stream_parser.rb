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

  class Nothing
    def to_s
      Nothing.to_s
    end
  end

  NOTHING = Nothing.new
  
  # the REXML::Parsers::PullParser used internally
  attr_reader :pull_parser

  def parse(data, &block)
    io = case data
         when IO
           data
         when String
           StringIO.new(data)
         end

    @pull_parser = REXML::Parsers::PullParser.new( io )
    block.call(self)
  ensure
    @pull_parser = nil
  end

  # find an element with name from element_names, ignoring
  # - encountering an end_element terminates and returns nil, leaving parser pointing to end_element
  # - encountering end_document terminates and returns nil
  # - name of found element is returned
  def find_element( element_names, ignore_element_names=[] )
    element_names = [ *element_names ]
    ignore_element_names = [ *ignore_element_names ]

    element_stack = []

    while( true )
      e = @pull_parser.peek
      if e.start_element?
        if element_stack.size == 0
          if element_names.include?( e[0] )
            return e[0]
          elsif element_names.empty? || ignore_element_names.include?( e[0] )
            element_stack.push( e[0] )
            @pull_parser.pull
          else
            raise "unexpected element: #{e.inspect}"
          end
        else # ignored content
          element_stack.push( e[0] )
          @pull_parser.pull
        end
      elsif e.end_element?
        if element_stack.size == 0
          return nil # returning from context, leaving parser on end element
        else
          if element_stack.last == e[0]
            element_stack.pop
            @pull_parser.pull
          else
            raise "mismatched end element: <#{e[0]}>"
          end
        end
      elsif e.end_document?
        raise "missing end tags: #{element_stack.inspect}" if element_stack.size>0
        return nil
      elsif e.text? 
        # ignore whitespace between elements
        raise "unexpected text content: #{e.inspect}" if e[0] !~ /[[:space:]]/ if element_stack.size>0
                                                                                 @pull_parser.pull
                                                                               else
                                                                                 @pull_parser.pull # other xml goop
                                                                               end
      end
    end

    # optionally find, and consume, an element
    #
    # if find=true, search for an element from element_names, ignoring whitespace. 
    # if find=false assume the parser is already pointing at such an element.
    # consume a start_element, call a block on the content, consume the end_element
    # returns the results of the block, or NOTHING if one wasn't found
    def element( element_names, find=true, &block )
      element_names = [ *element_names ]
      return NOTHING if find && ! find_element(element_names)

      e = @pull_parser.pull
      raise "expected start tag: <#{element_names.join('|')}>, got: #{e.inspect}" if ! e.start_element? || ! element_names.include?(e[0])
      name = e[0]
      attrs = e[1]
      
      # block should consume all element content, and leave parser on end_element, or
      # whitespace before it
      r = block.call(name, attrs)
      
      e = @pull_parser.pull
      e = @pull_parser.pull if e.text? && e[0] =~ /[[:space:]]/
      raise "expected end tag: #{name}, got: #{e.inspect}" if ! e.end_element? || e[0] != name
      
      r
    end

    # find and consume elements, calling block on each one found
    def elements( element_names, &block )
      while (NOTHING != element(element_names,&block))
      end
    end

    # consume text
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
