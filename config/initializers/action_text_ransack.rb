# Add ransackable attributes to ActionText::RichText for ActiveAdmin search
# Use an after_initialize callback to ensure all Rails components are loaded
Rails.application.config.after_initialize do
  ActionText::RichText.class_eval do
    def self.ransackable_attributes(auth_object = nil)
      %w[body created_at id name record_id record_type updated_at]
    end

    def self.ransackable_associations(auth_object = nil)
      []
    end
  end
end