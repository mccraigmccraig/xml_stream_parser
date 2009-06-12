#!/usr/bin/env spec

require 'rubygems'
require 'spec'
require 'set'
require File.expand_path( File.join( File.dirname(__FILE__) , ".." , "lib", "xml_stream_parser" ) )

describe XmlStreamParser do
  it "should work on a StringIO" do
    io = StringIO.new( "<foo/>")
    XmlStreamParser.new.parse(io) do |p|
      p.element("foo") do |name,attrs|
        name.should ==("foo")
        name
      end
    end.should ==("foo")
  end

  it "should parse a simple one element document" do
    XmlStreamParser.new.parse( "<foo></foo>" ) do |p|
      called = false
      p.element("foo") { |name,attrs|
        called = true
        name.should ==("foo")
        attrs.should ==({})
      }
      called.should ==(true)
    end
  end
  
  describe "find_element" do
    
    it "should skip whitespace to find an element" do
      XmlStreamParser.new.parse( "   \n\n\n<foo></foo>") do |p|
        name = p.find_element("foo")
        name.should ==("foo")
        e = p.pull_parser.pull
        e.start_element?.should ==(true)
        e[0].should == "foo"
        e[1].should == {}
      end
    end

    it "should return NOTHING on unexpected elements" do
      XmlStreamParser.new.parse( "<foo></foo>") do |p|
        p.find_element("bar")
      end.should ==(XmlStreamParser::NOTHING)
    end

    it "should match one of multiple elements" do
      XmlStreamParser.new.parse( "<foo></foo>" ) do |p|
        p.find_element( ["bar","foo" ] )
      end.should ==("foo")
    end


    it "should return END_CONTEXT if element context terminates" do |p|
      called = false
      XmlStreamParser.new.parse( '<foo></foo>' ) do |p|
        p.element("foo") do |name,attrs|
          name.should ==("foo")

          n = p.find_element("bar")
          n.should ==(XmlStreamParser::END_CONTEXT)

          e = p.pull_parser.peek
          e.end_element?.should ==(true)
          e[0].should ==("foo")

          called = true
        end
      end
      called.should ==(true)
    end

    it "should return END_CONTEXT if document ends" do |p|
      XmlStreamParser.new.parse( '<foo></foo>') do |p|
        p.element("foo") do |name,attrs|
        end
        f = p.find_element("bar")
        f.should ==( XmlStreamParser::END_CONTEXT )
      end
    end
  end

  describe "discard" do
    
    it "should discard text content of an element" do |p|
      XmlStreamParser.new.parse( '<foo>blah blah blah</foo>') do |p|
        p.element("foo") do |name,attrs|
          p.discard
          "foo"
        end
      end.should ==("foo")
    end

    it "should discard element content of an element" do |p|
      XmlStreamParser.new.parse( '<foo><bar/><foobar></foobar></foo>') do |p|
        p.element("foo") do |name,attrs|
          p.discard
          "foo"
        end
      end.should ==("foo")
    end

    it "should discard mixed content of an element" do |p|
      XmlStreamParser.new.parse( '<foo><bar/>blah blah<foobar></foobar> blah blah </foo>') do |p|
        p.element("foo") do |name,attrs|
          p.discard
          "foo"
        end
      end.should ==("foo")
    end

  end

  describe "element" do

    it "should return NOTHING if optional and element not found" do
      XmlStreamParser.new.parse( '<foo><foofoo/></foo>' ) do |p|
        p.element("foo") do |name,attrs|
          p.element("bar",true) do |name,attrs|
            "bar"
          end.should ==(XmlStreamParser::NOTHING)
          p.element("foofoo") do |name,attrs|
            "foofoo"
          end
        end
      end.should ==("foofoo" )
    end

    it "should return END_CONTEXT if optional and context ends" do
      XmlStreamParser.new.parse( '<foo></foo>' ) do |p|
        p.element("foo") do |name,attrs|
          p.element("bar",true) do |name,attrs|
            "bar"
          end.should ==(XmlStreamParser::END_CONTEXT)
          "foofoo"
        end
      end.should ==("foofoo")
    end

    it "should not propagate sentinel values up the call hierarchy" do
      called = false
      XmlStreamParser.new.parse( '<foo></foo>' ) do |p|
        p.element("foo") do |name,attrs|
          called = true
          p.element("bar",true) do |name,attrs|
            "bar"
          end.should ==(XmlStreamParser::END_CONTEXT)
        end
      end.should_not ==(XmlStreamParser::END_CONTEXT)
      called.should == (true)
    end

    def parse_bar( p )
      p.element("bar") do |name,attrs|
        return "barbar"
      end
    end

    it "should consume the end tag even if block calls return" do
      XmlStreamParser.new.parse( '<foo><bar/></foo>') do |p|
        p.element( "foo" ) do |name, attrs|
          parse_bar( p )
        end
      end.should ==("barbar" )
    end

    it "should consume the end tag even if block calls break" do
      XmlStreamParser.new.parse( '<foo><bar/></foo>') do |p|
        p.element( "foo" ) do |name, attrs|
          p.element( "bar" ) do |name, attrs|
            break
          end
          "foo"
        end
      end.should ==( "foo" )
    end

    it "should raise on premature document termination" do
      lambda {
        XmlStreamParser.new.parse( '<foo>' ) do |p|
          p.element("foo") do |name,attrs|
            p.element("bar",false) do |name,attrs|
              "bar"
            end
          end
        end
      }.should raise_error(RuntimeError)
    end

    it "should raise on premature context termination" do
      lambda {
        XmlStreamParser.new.parse( '<foo></foo>' ) do |p|
          p.element("foo") do |name,attrs|
            p.element("bar",false) do |name,attrs|
              "bar"
            end
          end
        end
      }.should raise_error(RuntimeError)
    end

    it "should consume an element, giving name and attributes to the provided block and returning block result" do
      XmlStreamParser.new.parse( '<foo a="one" b="two"></foo>') do |p|
        p.element( "foo" ) do |name, attrs|
          name.should ==("foo")
          attrs.should ==({ "a"=>"one", "b"=>"two" })
          "blockresult"
        end.should ==("blockresult")
        e = p.pull_parser.peek
        e.end_document?.should ==(true)
        "foofoo"
      end.should ==("foofoo")
    end

    it "should consume one of many element names, giving name and attrs to block and returning block result" do
      XmlStreamParser.new.parse( '<foo a="one" b="two"></foo>') do |p|
        p.element( ["bar","foo"] ) do |name, attrs|
          name.should ==("foo")
          attrs.should ==({ "a"=>"one", "b"=>"two" })
          "blockresult"
        end
      end.should ==("blockresult")
    end

    it "should ignore whitespace inside element" do
      XmlStreamParser.new.parse( '<foo a="one" b="two">  \n  \n</foo>') do |p|
        p.element( "foo" ) do |name, attrs|
          name.should ==("foo")
          attrs.should ==({ "a"=>"one", "b"=>"two" })
          "blockresult"
        end.should ==("blockresult")
        e = p.pull_parser.peek
        e.end_document?.should ==(true)
        "foofoo"
      end.should ==("foofoo")
    end

  end

  describe "text" do
    it "should consume an element with text content and give it's name, attrs, text to the block and return the block result" do
      XmlStreamParser.new.parse( '<foo a="bar">hello mum</foo>') do |p|
        p.element( "foo" ) do |name, attrs|
          name.should ==("foo")
          attrs.should ==({ "a"=>"bar" })
          p.text
        end
      end.should ==("hello mum")
    end

    it "should raise if the element contains element content" do
      lambda {
        XmlStreamParser.new.parse( '<foo a="bar"><bar/></foo>') do |p|
          p.element("foo") do |name,attrs|
            p.text()
          end
        end
      }.should raise_error(RuntimeError)
    end

    it "should raise if the element contains mixed content" do
      lambda {
        XmlStreamParser.new.parse( '<foo a="bar">some <bar/> text</foo>') do |p|
          p.element("foo") do |name,attrs|
            p.text()
          end
        end
      }.should raise_error(RuntimeError)
    end
  end

  describe "elements" do
    it "should consume multiple elements" do
      el_counts = Hash.new(0)
      XmlStreamParser.new.parse( '<foo><bar/><bar/><foobar/></foo>') do |p|
        p.element("foo") do |name,attrs|
          p.elements( ["bar","foobar"] ) do |name,attrs|
            el_counts[name] += 1
          end
        end
      end
      el_counts.should ==({ "bar"=>2, "foobar"=>1 })
    end

    it "should not complain if there are no matching elements" do
      XmlStreamParser.new.parse( '<foo></foo>') do |p|
        p.element("foo") do |name,attrs|
          p.elements( ["bar","foobar"] ) do |name,attrs|
            el_counts[name] += 1
          end
        end
      end
    end
    
  end

  describe "some more complex examples" do

    it "should parse a list of people" do
      doc = <<-EOF
<people>
  <person name="alice">likes cheese</person>
  <person name="bob">likes music</person>
  <person name="charles">likes alice</person>
</people>
EOF

      XmlStreamParser.new.parse(doc) do |p|
        people = {}
        
        p.element("people") do |name,attrs|
          p.elements("person") do |name, attrs|
            people[attrs["name"]] = p.text
          end
        end

        people
      end.should ==({ "alice"=>"likes cheese",
                      "bob"=>"likes music",
                      "charles"=>"likes alice"})
    end

    it "should parse a list of people and their friends" do
      doc = <<-EOF
<people>
  <person name="alice">
    <friend name="bob"/>
    <likes>cheese</likes>
    <friend name="charles"/>
  </person>
  <person name="bob">
    <friend name="alice"/>
    <likes>wolf dogs</likes>
  </person>
  <person name="charles">
    <friend name="alice"/>
    <likes>bach</likes>
  </person>
</people>
EOF
      
      XmlStreamParser.new.parse(doc) do |p|
        people = Hash.new{ |h,k| h[k] = {:friends=>Set.new([]), :likes=>Set.new([]) } }
        
        p.element("people") do |name,attrs|
          p.elements("person") do |name, attrs|
            person_name = attrs["name"]
            people[person_name]

            p.elements(["friend","likes"]) do |name,attrs|
              case name
              when "friend" then
                people[person_name][:friends] << attrs["name"]
              when "likes" then
                people[person_name][:likes] << p.text
              end
            end
          end
        end

        people
      end.should ==( { 
                       "alice"=>{ :friends=>Set.new(["bob","charles"]), :likes=>Set.new(["cheese"])},
                       "bob"=>{ :friends=>Set.new(["alice"]), :likes=>Set.new(["wolf dogs"])},
                       "charles"=>{ :friends=>Set.new(["alice"]), :likes=>Set.new(["bach"])}
                     }) 

    end

  end

end
