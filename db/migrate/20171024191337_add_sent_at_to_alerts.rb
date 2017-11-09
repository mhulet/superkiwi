class AddSentAtToAlerts < ActiveRecord::Migration[5.1]
  def change
    add_column :alerts, :sent_at, :datetime
  end
end
