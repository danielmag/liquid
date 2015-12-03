# Copyright (c) 2005 Tobias Luetke
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

module Twig
  FilterSeparator             = /\|/
  ArgumentSeparator           = ','.freeze
  FilterArgumentSeparator     = ':'.freeze
  VariableAttributeSeparator  = '.'.freeze
  TagStart                    = /\{\%/
  TagEnd                      = /\%\}/
  VariableSignature           = /\(?[\w\-\.\[\]]\)?/
  VariableSegment             = /[\w\-]/
  VariableStart               = /\{\{/
  VariableEnd                 = /\}\}/
  VariableIncompleteEnd       = /\}\}?/
  QuotedString                = /"[^"]*"|'[^']*'/
  QuotedFragment              = /#{QuotedString}|(?:[^\s,\|'"]|#{QuotedString})+/o
  TagAttributes               = /(\w+)\s*\:\s*(#{QuotedFragment})/o
  AnyStartingTag              = /\{\{|\{\%/
  PartialTemplateParser       = /#{TagStart}.*?#{TagEnd}|#{VariableStart}.*?#{VariableIncompleteEnd}/om
  TemplateParser              = /(#{PartialTemplateParser}|#{AnyStartingTag})/om
  VariableParser              = /\[[^\]]+\]|#{VariableSegment}+\??/o

  singleton_class.send(:attr_accessor, :cache_classes)
  self.cache_classes = true
end

require "twig/version"
require 'twig/lexer'
require 'twig/parser'
require 'twig/i18n'
require 'twig/drop'
require 'twig/extensions'
require 'twig/errors'
require 'twig/interrupts'
require 'twig/strainer'
require 'twig/expression'
require 'twig/context'
require 'twig/parser_switching'
require 'twig/tag'
require 'twig/block'
require 'twig/document'
require 'twig/variable'
require 'twig/variable_lookup'
require 'twig/range_lookup'
require 'twig/file_system'
require 'twig/template'
require 'twig/standardfilters'
require 'twig/condition'
require 'twig/module_ex'
require 'twig/utils'
require 'twig/token'
require 'twig/register_in_tilt'

# Load all the tags of the standard library
#
Dir[File.dirname(__FILE__) + '/twig/tags/*.rb'].each { |f| require f }

require 'twig/profiler'
require 'twig/profiler/hooks'
