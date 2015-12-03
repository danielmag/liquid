$:.unshift File.dirname(__FILE__) + '/../../lib'
require File.dirname(__FILE__) + '/../../lib/twig'

require File.dirname(__FILE__) + '/comment_form'
require File.dirname(__FILE__) + '/paginate'
require File.dirname(__FILE__) + '/json_filter'
require File.dirname(__FILE__) + '/money_filter'
require File.dirname(__FILE__) + '/shop_filter'
require File.dirname(__FILE__) + '/tag_filter'
require File.dirname(__FILE__) + '/weight_filter'

Twig::Template.register_tag 'paginate', Paginate
Twig::Template.register_tag 'form', CommentForm

Twig::Template.register_filter JsonFilter
Twig::Template.register_filter MoneyFilter
Twig::Template.register_filter WeightFilter
Twig::Template.register_filter ShopFilter
Twig::Template.register_filter TagFilter
