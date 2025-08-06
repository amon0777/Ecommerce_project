ActiveAdmin.register Category do
  # Allow permitted parameters
  permit_params :name

  # Filters
  filter :products_name_cont, as: :string, label: 'Product Name'

  # Index page customization
  index do
    selectable_column
    id_column
    column :name
    column :created_at
    actions
  end

  # Form for new/edit
  form do |f|
    f.inputs "Category Details" do
      f.input :name
    end
    f.actions
  end
end
