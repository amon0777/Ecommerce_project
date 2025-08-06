class Product < ApplicationRecord
  belongs_to :category
  has_one_attached :image

  monetize :price_cents
  monetize :sale_price_cents, allow_nil: true

  scope :newly_added, -> { where("created_at >= ?", 3.days.ago) }
  scope :recently_updated, -> {
  where("updated_at >= ?", 3.days.ago)
    .where("created_at < ?", 3.days.ago)
}

  scope :on_sale, -> {
    where.not(sale_price_cents: nil).where("sale_price_cents < price_cents")
  }

  def on_sale?
    sale_price.present? && sale_price < price
  end

  def effective_price
    on_sale? ? sale_price : price
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[name description price_cents category_id created_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[category image_attachment image_blob]
  end
end
