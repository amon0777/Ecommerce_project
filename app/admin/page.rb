# app/admin/pages.rb

ActiveAdmin.register Page do
  permit_params :title, :slug, :description, :body

  # Configure which fields can be filtered
  filter :title
  filter :slug
  filter :created_at
  filter :updated_at

  # Don't try to filter rich text content directly
  # Remove any filters for :content, :description, :body etc.

  index do
    selectable_column
    id_column
    column :title
    column :slug
    column :created_at
    column :updated_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :title
      row :slug
      row :description do |page|
        page.description
      end
      row :body do |page|
        page.body
      end
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.inputs do
      f.input :title
      f.input :slug
      f.input :description
      f.input :body
    end
    f.actions
  end
end
