require 'test_helper'

class ContextDrop < Twig::Drop
  def scopes
    @context.scopes.size
  end

  def scopes_as_array
    (1..@context.scopes.size).to_a
  end

  def loop_pos
    @context['forloop.index']
  end

  def before_method(method)
    return @context[method]
  end
end

class ProductDrop < Twig::Drop

  class TextDrop < Twig::Drop
    def array
      ['text1', 'text2']
    end

    def text
      'text1'
    end
  end

  class CatchallDrop < Twig::Drop
    def before_method(method)
      return 'method: ' << method.to_s
    end
  end

  def texts
    TextDrop.new
  end

  def catchall
    CatchallDrop.new
  end

  def context
    ContextDrop.new
  end

  def user_input
    "foo".taint
  end

  protected
    def callmenot
      "protected"
    end
end

class EnumerableDrop < Twig::Drop
  def before_method(method)
    method
  end

  def size
    3
  end

  def first
    1
  end

  def count
    3
  end

  def min
    1
  end

  def max
    3
  end

  def each
    yield 1
    yield 2
    yield 3
  end
end

class RealEnumerableDrop < Twig::Drop
  include Enumerable

  def before_method(method)
    method
  end

  def each
    yield 1
    yield 2
    yield 3
  end
end

class DropsTest < Minitest::Test
  include Twig

  def test_product_drop
    tpl = Twig::Template.parse('  ')
    assert_equal '  ', tpl.render!('product' => ProductDrop.new)
  end

  def test_rendering_raises_on_tainted_attr
    with_taint_mode(:error) do
      tpl = Twig::Template.parse('{{ product.user_input }}')
      assert_raises TaintedError do
        tpl.render!('product' => ProductDrop.new)
      end
    end
  end

  def test_rendering_warns_on_tainted_attr
    with_taint_mode(:warn) do
      tpl = Twig::Template.parse('{{ product.user_input }}')
      tpl.render!('product' => ProductDrop.new)
      assert_match /tainted/, tpl.warnings.first
    end
  end

  def test_rendering_doesnt_raise_on_escaped_tainted_attr
    with_taint_mode(:error) do
      tpl = Twig::Template.parse('{{ product.user_input | escape }}')
      tpl.render!('product' => ProductDrop.new)
    end
  end

  def test_drop_does_only_respond_to_whitelisted_methods
    assert_equal "", Twig::Template.parse("{{ product.inspect }}").render!('product' => ProductDrop.new)
    assert_equal "", Twig::Template.parse("{{ product.pretty_inspect }}").render!('product' => ProductDrop.new)
    assert_equal "", Twig::Template.parse("{{ product.whatever }}").render!('product' => ProductDrop.new)
    assert_equal "", Twig::Template.parse('{{ product | map: "inspect" }}').render!('product' => ProductDrop.new)
    assert_equal "", Twig::Template.parse('{{ product | map: "pretty_inspect" }}').render!('product' => ProductDrop.new)
    assert_equal "", Twig::Template.parse('{{ product | map: "whatever" }}').render!('product' => ProductDrop.new)
  end

  def test_drops_respond_to_to_twig
    assert_equal "text1", Twig::Template.parse("{{ product.to_twig.texts.text }}").render!('product' => ProductDrop.new)
    assert_equal "text1", Twig::Template.parse('{{ product | map: "to_twig" | map: "texts" | map: "text" }}').render!('product' => ProductDrop.new)
  end

  def test_text_drop
    output = Twig::Template.parse( ' {{ product.texts.text }} '  ).render!('product' => ProductDrop.new)
    assert_equal ' text1 ', output
  end

  def test_unknown_method
    output = Twig::Template.parse( ' {{ product.catchall.unknown }} '  ).render!('product' => ProductDrop.new)
    assert_equal ' method: unknown ', output
  end

  def test_integer_argument_drop
    output = Twig::Template.parse( ' {{ product.catchall[8] }} '  ).render!('product' => ProductDrop.new)
    assert_equal ' method: 8 ', output
  end

  def test_text_array_drop
    output = Twig::Template.parse( '{% for text in product.texts.array %} {{text}} {% endfor %}'  ).render!('product' => ProductDrop.new)
    assert_equal ' text1  text2 ', output
  end

  def test_context_drop
    output = Twig::Template.parse( ' {{ context.bar }} '  ).render!('context' => ContextDrop.new, 'bar' => "carrot")
    assert_equal ' carrot ', output
  end

  def test_nested_context_drop
    output = Twig::Template.parse( ' {{ product.context.foo }} '  ).render!('product' => ProductDrop.new, 'foo' => "monkey")
    assert_equal ' monkey ', output
  end

  def test_protected
    output = Twig::Template.parse( ' {{ product.callmenot }} '  ).render!('product' => ProductDrop.new)
    assert_equal '  ', output
  end

  def test_object_methods_not_allowed
    [:dup, :clone, :singleton_class, :eval, :class_eval, :inspect].each do |method|
      output = Twig::Template.parse(" {{ product.#{method} }} ").render!('product' => ProductDrop.new)
      assert_equal '  ', output
    end
  end

  def test_scope
    assert_equal '1', Twig::Template.parse( '{{ context.scopes }}'  ).render!('context' => ContextDrop.new)
    assert_equal '2', Twig::Template.parse( '{%for i in dummy%}{{ context.scopes }}{%endfor%}'  ).render!('context' => ContextDrop.new, 'dummy' => [1])
    assert_equal '3', Twig::Template.parse( '{%for i in dummy%}{%for i in dummy%}{{ context.scopes }}{%endfor%}{%endfor%}'  ).render!('context' => ContextDrop.new, 'dummy' => [1])
  end

  def test_scope_though_proc
    assert_equal '1', Twig::Template.parse( '{{ s }}'  ).render!('context' => ContextDrop.new, 's' => Proc.new{|c| c['context.scopes'] })
    assert_equal '2', Twig::Template.parse( '{%for i in dummy%}{{ s }}{%endfor%}'  ).render!('context' => ContextDrop.new, 's' => Proc.new{|c| c['context.scopes'] }, 'dummy' => [1])
    assert_equal '3', Twig::Template.parse( '{%for i in dummy%}{%for i in dummy%}{{ s }}{%endfor%}{%endfor%}'  ).render!('context' => ContextDrop.new, 's' => Proc.new{|c| c['context.scopes'] }, 'dummy' => [1])
  end

  def test_scope_with_sets
    assert_equal 'variable', Twig::Template.parse( '{% set a = "variable"%}{{a}}'  ).render!('context' => ContextDrop.new)
    assert_equal 'variable', Twig::Template.parse( '{% set a = "variable"%}{%for i in dummy%}{{a}}{%endfor%}'  ).render!('context' => ContextDrop.new, 'dummy' => [1])
    assert_equal 'test', Twig::Template.parse( '{% set header_gif = "test"%}{{header_gif}}'  ).render!('context' => ContextDrop.new)
    assert_equal 'test', Twig::Template.parse( "{% set header_gif = 'test'%}{{header_gif}}"  ).render!('context' => ContextDrop.new)
  end

  def test_scope_from_tags
    assert_equal '1', Twig::Template.parse( '{% for i in context.scopes_as_array %}{{i}}{% endfor %}'  ).render!('context' => ContextDrop.new, 'dummy' => [1])
    assert_equal '12', Twig::Template.parse( '{%for a in dummy%}{% for i in context.scopes_as_array %}{{i}}{% endfor %}{% endfor %}'  ).render!('context' => ContextDrop.new, 'dummy' => [1])
    assert_equal '123', Twig::Template.parse( '{%for a in dummy%}{%for a in dummy%}{% for i in context.scopes_as_array %}{{i}}{% endfor %}{% endfor %}{% endfor %}'  ).render!('context' => ContextDrop.new, 'dummy' => [1])
  end

  def test_access_context_from_drop
    assert_equal '123', Twig::Template.parse( '{%for a in dummy%}{{ context.loop_pos }}{% endfor %}'  ).render!('context' => ContextDrop.new, 'dummy' => [1,2,3])
  end

  def test_enumerable_drop
    assert_equal '123', Twig::Template.parse( '{% for c in collection %}{{c}}{% endfor %}').render!('collection' => EnumerableDrop.new)
  end

  def test_enumerable_drop_size
    assert_equal '3', Twig::Template.parse( '{{collection.size}}').render!('collection' => EnumerableDrop.new)
  end

  def test_enumerable_drop_will_invoke_before_method_for_clashing_method_names
    ["select", "each", "map", "cycle"].each do |method|
      assert_equal method.to_s, Twig::Template.parse("{{collection.#{method}}}").render!('collection' => EnumerableDrop.new)
      assert_equal method.to_s, Twig::Template.parse("{{collection[\"#{method}\"]}}").render!('collection' => EnumerableDrop.new)
      assert_equal method.to_s, Twig::Template.parse("{{collection.#{method}}}").render!('collection' => RealEnumerableDrop.new)
      assert_equal method.to_s, Twig::Template.parse("{{collection[\"#{method}\"]}}").render!('collection' => RealEnumerableDrop.new)
    end
  end

  def test_some_enumerable_methods_still_get_invoked
    [ :count, :max ].each do |method|
      assert_equal "3", Twig::Template.parse("{{collection.#{method}}}").render!('collection' => RealEnumerableDrop.new)
      assert_equal "3", Twig::Template.parse("{{collection[\"#{method}\"]}}").render!('collection' => RealEnumerableDrop.new)
      assert_equal "3", Twig::Template.parse("{{collection.#{method}}}").render!('collection' => EnumerableDrop.new)
      assert_equal "3", Twig::Template.parse("{{collection[\"#{method}\"]}}").render!('collection' => EnumerableDrop.new)
    end

    assert_equal "yes", Twig::Template.parse("{% if collection contains 3 %}yes{% endif %}").render!('collection' => RealEnumerableDrop.new)

    [ :min, :first ].each do |method|
      assert_equal "1", Twig::Template.parse("{{collection.#{method}}}").render!('collection' => RealEnumerableDrop.new)
      assert_equal "1", Twig::Template.parse("{{collection[\"#{method}\"]}}").render!('collection' => RealEnumerableDrop.new)
      assert_equal "1", Twig::Template.parse("{{collection.#{method}}}").render!('collection' => EnumerableDrop.new)
      assert_equal "1", Twig::Template.parse("{{collection[\"#{method}\"]}}").render!('collection' => EnumerableDrop.new)
    end
  end

  def test_empty_string_value_access
    assert_equal '', Twig::Template.parse('{{ product[value] }}').render!('product' => ProductDrop.new, 'value' => '')
  end

  def test_nil_value_access
    assert_equal '', Twig::Template.parse('{{ product[value] }}').render!('product' => ProductDrop.new, 'value' => nil)
  end

  def test_default_to_s_on_drops
    assert_equal 'ProductDrop', Twig::Template.parse("{{ product }}").render!('product' => ProductDrop.new)
    assert_equal 'EnumerableDrop', Twig::Template.parse('{{ collection }}').render!('collection' => EnumerableDrop.new)
  end
end # DropsTest
