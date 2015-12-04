module Twig

  # Set sets a variable in your template.
  #
  #   {% set foo = 'monkey' %}
  #
  # You can then use the variable later in the page.
  #
  #  {{ foo }}
  #
  class SetTag < Block
    TagSyntax = /(#{VariableSignature}+)\s*=\s*(.*)\s*/om
    BlockSyntax = /(#{VariableSignature}+)/o

    def initialize(tag_name, markup, options)
      super
      if markup =~ TagSyntax
        @to = $1
        @from = Variable.new($2,options)
        @from.line_number = line_number
        @is_block = false
      elsif markup =~ BlockSyntax
        @to = $1
        @is_block = true
      else
        raise SyntaxError.new options[:locale].t("errors.syntax.set".freeze)
      end
    end

    def render(context)
      val = @is_block ? super : @from.render(context)
      context.scopes.last[@to] = val
      context.increment_used_resources(:assign_score_current, val)
      ''.freeze
    end

    def blank?
      true
    end

    def parse(tokens)
      super if @is_block
    end
  end

  Template.register_tag('set'.freeze, SetTag)
end
