ActiveAdmin.register Product do
  permit_params :name, :description, :sale_price_cents, :price_cents, :category_id, :image

  # ✅ Allow only valid filters to prevent Ransack errors
  filter :name
  filter :description
  filter :price_cents
  filter :category
  filter :created_at

  form do |f|
    f.inputs do
      f.input :name
      f.input :description
      f.input :sale_price_cents, label: "Sale Price (optional)"
      f.input :price_cents, label: "Price (in cents)"
      f.input :category, as: :select, collection: Category.all
      f.input :image, as: :file
    end
    f.actions
  end

  # Optional: Customize how products appear in the index table
  index do
    selectable_column
    id_column
    column :name
    column :description
    column("Price") { |product| "$#{product.price_cents.to_f / 100}" }
    column :category
    column("Image") do |product|
      if product.image.attached?
        image_tag url_for(product.image), size: "100x100"
      end
    end
    actions
  end
end
