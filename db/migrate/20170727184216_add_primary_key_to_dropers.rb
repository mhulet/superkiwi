class AddPrimaryKeyToDropers < ActiveRecord::Migration[5.1]
  def change
    execute "ALTER TABLE dropers ADD PRIMARY KEY (id);"
  end
end
