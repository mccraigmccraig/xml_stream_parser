#!/usr/bin/env spec

require 'rubygems'
require 'spec'
require File.expand_path( File.join( File.dirname(__FILE__) , ".." , "lib", "xml_stream_parser" ) )

describe XmlStreamParser do
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

    it "should raise on premature document termination" do
      lambda {
        XmlStreamParser.new.parse( '<foo>' ) do |p|
          name = p.find_element( "bar", "foo" )
        end
      }.should raise_error(RuntimeError)
    end

    it "should return nil if element context terminates" do |p|
      called = false
      XmlStreamParser.new.parse( '<foo> </foo>' ) do |p|
        p.element("foo") do |name,attrs|
          name.should ==("foo")

          n = p.find_element("bar")
          n.should ==(nil)

          e = p.pull_parser.peek
          e.end_element?.should ==(true)
          e[0].should ==("foo")

          called = true
        end
      end
      called.should ==(true)
    end
  end

  describe "consume" do
    
    it "should consume an element, giving name and attributes to the provided block and returning block result" do
      XmlStreamParser.new.parse( '<foo a="one" b="two"></foo>') do |p|
        p.element( "foo" ) do |name, attrs|
          name.should ==("foo")
          attrs.should ==({ "a"=>"one", "b"=>"two" })
        end.should ==("foo")
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
        end
      end.should ==("foo")
    end

    it "should ignore whitespace inside element" do |p|
      XmlStreamParser.new.parse( '<foo a="one" b="two">  \n  \n</foo>') do |p|
        p.element( "foo" ) do |name, attrs|
          name.should ==("foo")
          attrs.should ==({ "a"=>"one", "b"=>"two" })
        end.should ==("foo")
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
          p.text.should ==("hello mum")
        end
      end.should ==("foo")
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
        people = {}
        friends = {}
        
        p.element("people") do |name,attrs|
          p.elements("person") do |name, attrs|
            person_name = attrs["name"]
            people[person_name] ||= {:friends=>Set.new([]), :likes=>Set.new([]) }

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
