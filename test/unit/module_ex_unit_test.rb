require 'test_helper'

class TestClassA
  twig_methods :allowedA, :chainedB
  def allowedA
    'allowedA'
  end
  def restrictedA
    'restrictedA'
  end
  def chainedB
    TestClassB.new
  end
end

class TestClassB
  twig_methods :allowedB, :chainedC
  def allowedB
    'allowedB'
  end
  def chainedC
    TestClassC.new
  end
end

class TestClassC
  twig_methods :allowedC
  def allowedC
    'allowedC'
  end
end

class TestClassC::TwigDropClass
  def another_allowedC
    'another_allowedC'
  end
end

class ModuleExUnitTest < Minitest::Test
  include Twig

  def setup
    @a = TestClassA.new
    @b = TestClassB.new
    @c = TestClassC.new
  end

  def test_should_create_TwigDropClass
    assert TestClassA::TwigDropClass
    assert TestClassB::TwigDropClass
    assert TestClassC::TwigDropClass
  end

  def test_should_respond_to_twig
    assert @a.respond_to?(:to_twig)
    assert @b.respond_to?(:to_twig)
    assert @c.respond_to?(:to_twig)
  end

  def test_should_return_TwigDropClass_object
    assert @a.to_twig.is_a?(TestClassA::TwigDropClass)
    assert @b.to_twig.is_a?(TestClassB::TwigDropClass)
    assert @c.to_twig.is_a?(TestClassC::TwigDropClass)
  end

  def test_should_respond_to_twig_methods
    assert @a.to_twig.respond_to?(:allowedA)
    assert @a.to_twig.respond_to?(:chainedB)
    assert @b.to_twig.respond_to?(:allowedB)
    assert @b.to_twig.respond_to?(:chainedC)
    assert @c.to_twig.respond_to?(:allowedC)
    assert @c.to_twig.respond_to?(:another_allowedC)
  end

  def test_should_not_respond_to_restricted_methods
    assert ! @a.to_twig.respond_to?(:restricted)
  end

  def test_should_use_regular_objects_as_drops
    assert_template_result 'allowedA', "{{ a.allowedA }}", 'a'=>@a
    assert_template_result 'allowedB', "{{ a.chainedB.allowedB }}", 'a'=>@a
    assert_template_result 'allowedC', "{{ a.chainedB.chainedC.allowedC }}", 'a'=>@a
    assert_template_result 'another_allowedC', "{{ a.chainedB.chainedC.another_allowedC }}", 'a'=>@a
    assert_template_result '', "{{ a.restricted }}", 'a'=>@a
    assert_template_result '', "{{ a.unknown }}", 'a'=>@a
  end
end # ModuleExTest
