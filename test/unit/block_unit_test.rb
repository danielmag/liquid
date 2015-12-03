require 'test_helper'

class BlockUnitTest < Minitest::Test
  include Twig

  def test_blankspace
    template = Twig::Template.parse("  ")
    assert_equal ["  "], template.root.nodelist
  end

  def test_variable_beginning
    template = Twig::Template.parse("{{funk}}  ")
    assert_equal 2, template.root.nodelist.size
    assert_equal Variable, template.root.nodelist[0].class
    assert_equal String, template.root.nodelist[1].class
  end

  def test_variable_end
    template = Twig::Template.parse("  {{funk}}")
    assert_equal 2, template.root.nodelist.size
    assert_equal String, template.root.nodelist[0].class
    assert_equal Variable, template.root.nodelist[1].class
  end

  def test_variable_middle
    template = Twig::Template.parse("  {{funk}}  ")
    assert_equal 3, template.root.nodelist.size
    assert_equal String, template.root.nodelist[0].class
    assert_equal Variable, template.root.nodelist[1].class
    assert_equal String, template.root.nodelist[2].class
  end

  def test_variable_many_embedded_fragments
    template = Twig::Template.parse("  {{funk}} {{so}} {{brother}} ")
    assert_equal 7, template.root.nodelist.size
    assert_equal [String, Variable, String, Variable, String, Variable, String],
                 block_types(template.root.nodelist)
  end

  def test_with_block
    template = Twig::Template.parse("  {% comment %} {% endcomment %} ")
    assert_equal [String, Comment, String], block_types(template.root.nodelist)
    assert_equal 3, template.root.nodelist.size
  end

  def test_with_custom_tag
    Twig::Template.register_tag("testtag", Block)
    assert Twig::Template.parse( "{% testtag %} {% endtesttag %}")
  end

  private
    def block_types(nodelist)
      nodelist.collect { |node| node.class }
    end
end # VariableTest
