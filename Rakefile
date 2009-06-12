#!/usr/bin/env jruby

require 'rubygems'
require 'rake'
require 'rake/gempackagetask'
require 'rake/clean'
require 'spec/rake/spectask'
require 'hoe'
require 'lib/xml_stream_parser'

CLEAN << 'pkg'

$LOAD_PATH << "lib"

gemspec = File.join( File.dirname(__FILE__), 'xml_stream_parser.gemspec' )

Hoe.new("xml_stream_parser", XmlStreamParser::VERSION ) do |p|
  p.description = %q{xml_stream_parser is a *very* basic Ruby parser for xml streams, based on REXML\'s pull parser}
  p.email =  "craig@trampolinesystems.com"
  p.author =  "craig mcmillan"
  p.testlib = "spec"
end

task :cultivate do
  system "touch Manifest.txt; jrake check_manifest | grep -v \"(in \" | patch"
  system "jrake debug_gem | grep -v \"(in \" > #{gemspec}"
end

Spec::Rake::SpecTask.new do |t|
  t.name = :spec
  t.warning = false
  t.rcov = false
  t.spec_files = FileList["spec/**/*_spec.rb"]
  t.libs << "./lib"
end

