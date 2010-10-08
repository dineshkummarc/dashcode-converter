require 'json'
require 'nokogiri'
require 'erb'
require 'fileutils'

module DashcodeConverter
  
  JSON_PARAMS= {
    :indent=> "  ",
    :object_nl=> "\n",
    :array_nl=> "\n",
    :space=> " "
  }
  
  INDENT= "    "
  
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
require 'dashcode-converter/project'