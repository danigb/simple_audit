# Use this macro if you want changes in your model to be saved in an audit table.
# The audits table must exist.
#
#   class Booking
#     simple_audit
#   end
#
# See SimpleAudit::ClassMethods#simple_audit for configuration options

module SimpleAudit

  module Model
    def self.included(base) #:nodoc:
      base.send :extend, ClassMethods
    end

    module ClassMethods

      # == Configuration options
      #
      # * <tt>username_method => symbol</tt> - Call this method on the current user to get the name
      #
      # With no block, all the attributes of the audited model will be logged.
      #
      #    class Booking
      #      # this is equivalent to passing no block
      #      simple_audit do |audited_record|
      #        audited_record.attributes
      #      end
      #    end
      #
      # If a block is given, the data returned by the block will be saved in the audit's change log.
      #
      #    class Booking
      #      has_many :housing_units
      #      simple_audit do |audited_record|
      #        {
      #          :some_relevant_attribute => audited_record.some_relevant_attribute,
      #          :human_readable_serialization_of_aggregated_models => audited_record.housing_units.collect(&:to_s),
      #          ...
      #        }
      #      end
      #    end
      #

      def simple_audit(options = {}, &block)
	to_remove = options[:except]
	to_remove.map!{|k| k.to_s}
        class_eval do
		
          write_inheritable_attribute :username_method, (options[:username_method] || :name).to_sym
          class_inheritable_reader :username_method

          audit_changes_proc = block_given? ? block.to_proc : Proc.new {|record| record.attributes.except(to_remove)  }
          write_inheritable_attribute :audit_changes, audit_changes_proc
          class_inheritable_reader :audit_changes

          has_many :audits, :as => :auditable, :class_name => '::SimpleAudit::Audit' 

          after_create {|record| record.class.audit(record, :create)}
          after_update {|record| record.class.audit(record, :update)}

        end
      end

      def audit(record, action = :update, user = nil) #:nodoc:
	user_class = SimpleAudit.user_class_name.constantize
        user ||= user_class.current if user_class.respond_to?(:current)
        record.audits.create(:user => user,
          :username => user.try(self.username_method),
          :action => action.to_s,
          :change_log => self.audit_changes.call(record)
        )
      end
    end
    
  end
end
