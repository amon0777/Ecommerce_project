class Page < ApplicationRecord
  has_rich_text :description
  has_rich_text :body

  validates :slug, presence: true, uniqueness: true
  validates :title, presence: true

  def self.ransackable_attributes(auth_object = nil)
    %w[slug title created_at updated_at id]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[rich_text_body rich_text_description]
  end
end
