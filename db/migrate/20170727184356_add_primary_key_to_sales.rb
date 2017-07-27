class AddPrimaryKeyToSales < ActiveRecord::Migration[5.1]
  def change
    execute "ALTER TABLE sales ADD PRIMARY KEY (id);"
  end
end
