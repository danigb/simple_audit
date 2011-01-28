require 'active_record'
require 'action_view'

module SimpleAudit
  # Default tag used on hints.
  mattr_accessor :user_class_name
  @@user_class_name = "User"
end


require 'simple_audit/simple_audit'
require 'simple_audit/audit'
require 'simple_audit/helper'



if defined?(ActiveRecord::Base)
  ActiveRecord::Base.send :include, SimpleAudit::Model
end

if defined?(ActionView::Base)
  ActionView::Base.send :include, SimpleAudit::Helper
end
