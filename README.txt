= xml_stream_parser

this code was developed by trampoline systems [ http://trampolinesystems.com ]
as part of its sonar platform and released under a BSD licence for community use

http://www.github.com/mccraigmccraig/xml_stream_parser

== DESCRIPTION:

a basic library for pull parsing of large xml documents

== FEATURES:

 - pull parsing of large xml documents with no dom construction
 - provides simple operations for constructing higher level parsers

== PROBLEMS:

 - it's very basic
 - no validation

== SYNOPSIS:

require 'rubygems'
require 'xml_stream_parser'

# parse xml stream data, possibly never ending, and do things with it

doc = <<-EOF
<people>
  <person name="alice">likes cheese</person>
  <person name="bob">likes music</person>
  <person name="charles">likes alice</person>
</people>
EOF

# can be parsed with

people = {}
XmlStreamParser.new.parse_dsl(doc) do
  element "people" do |name,attrs|
    elements "person" do |name, attrs|
      people[attrs["name"]] = text
    end
  end
end

== REQUIREMENTS:

Ruby or JRuby

== INSTALL:

sudo gem sources -a http://gems.github.com
sudo gem install mccraigmccraig-xml_stream_parser

== LICENSE:

(The BSD License)

Copyright (c) 2009, Trampoline Systems Ltd, http://trampolinesystems.com/
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

  * Redistributions of source code must retain the above copyright notice,
    this list of conditions and the following disclaimer.
  * Redistributions in binary form must reproduce the above copyright notice,
    this list of conditions and the following disclaimer in the documentation
    and/or other materials provided with the distribution.
  * Neither the name of the <ORGANIZATION> nor the names of its contributors may
    be used to endorse or promote products derived from this software without
    specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
