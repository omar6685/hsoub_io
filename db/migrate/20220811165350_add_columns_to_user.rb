class AddColumnsToUser < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :first_name, :string
    add_column :users, :description, :text
    add_column :users, :country, :string
    add_column :users, :language, :string
    add_column :users, :gender, :string
    add_column :users, :birth_date, :date
  end
end
