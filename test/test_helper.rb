#!/usr/bin/env ruby

ENV["MT_NO_EXPECTATIONS"] = "1"
require 'minitest/autorun'
require 'spy/integration'

$:.unshift(File.join(File.expand_path(File.dirname(__FILE__)), '..', 'lib'))
require 'twig.rb'

mode = :strict
if env_mode = ENV['TWIG_PARSER_MODE']
  puts "-- #{env_mode.upcase} ERROR MODE"
  mode = env_mode.to_sym
end
Twig::Template.error_mode = mode

if Minitest.const_defined?('Test')
  # We're on Minitest 5+. Nothing to do here.
else
  # Minitest 4 doesn't have Minitest::Test yet.
  Minitest::Test = MiniTest::Unit::TestCase
end

module Minitest
  class Test
    def fixture(name)
      File.join(File.expand_path(File.dirname(__FILE__)), "fixtures", name)
    end
  end

  module Assertions
    include Twig

    def assert_template_result(expected, template, assigns = {}, message = nil)
      assert_equal expected, Template.parse(template).render!(assigns), message
    end

    def assert_template_result_matches(expected, template, assigns = {}, message = nil)
      return assert_template_result(expected, template, assigns, message) unless expected.is_a? Regexp

      assert_match expected, Template.parse(template).render!(assigns), message
    end

    def assert_match_syntax_error(match, template, registers = {})
      exception = assert_raises(Twig::SyntaxError) {
        Template.parse(template).render(assigns)
      }
      assert_match match, exception.message
    end

    def with_global_filter(*globals)
      original_global_strainer = Twig::Strainer.class_variable_get(:@@global_strainer)
      Twig::Strainer.class_variable_set(:@@global_strainer, Class.new(Twig::Strainer) do
        @filter_methods = Set.new
      end)
      Twig::Strainer.class_variable_get(:@@strainer_class_cache).clear

      globals.each do |global|
        Twig::Template.register_filter(global)
      end
      yield
    ensure
      Twig::Strainer.class_variable_get(:@@strainer_class_cache).clear
      Twig::Strainer.class_variable_set(:@@global_strainer, original_global_strainer)
    end

    def with_taint_mode(mode)
      old_mode = Twig::Template.taint_mode
      Twig::Template.taint_mode = mode
      yield
    ensure
      Twig::Template.taint_mode = old_mode
    end

    def with_error_mode(mode)
      old_mode = Twig::Template.error_mode
      Twig::Template.error_mode = mode
      yield
    ensure
      Twig::Template.error_mode = old_mode
    end
  end
end

class ThingWithToTwig
  def to_twig
    'foobar'
  end
end
