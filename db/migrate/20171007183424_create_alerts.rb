class CreateAlerts < ActiveRecord::Migration[5.1]
  def change
    create_table :alerts do |t|
      t.bigint :customer_id
      t.jsonb :categories_ids, null: false, default: '{}'
      t.boolean :enabled

      t.timestamps
    end
  end
end
