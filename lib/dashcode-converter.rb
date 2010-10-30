require 'json'
require 'nokogiri'
require 'erb'
require 'fileutils'
require 'v8'

module DashcodeConverter
  
  JSON_PARAMS= {
    :indent=> "  ",
    :object_nl=> "\n",
    :array_nl=> "\n",
    :space=> " "
  }
  
  INDENT= "    "
  
end

class JavascriptCode < String
  def to_json(*options)
    self
  end
end

module Kernel
  # A convenience factory method
  def JavascriptCode(str)
    JavascriptCode.new(str)
  end
end

class String
  def remove_indent
    match= self.match(/(^\s+)/)
    return self unless match
    self.gsub(/^#{match[1]}/, '').strip
  end
  def indent(str)
    self.gsub(/^/, str)
  end
end

require 'dashcode-converter/controller'
require 'dashcode-converter/nib'
require 'dashcode-converter/scripts'
require 'dashcode-converter/project'