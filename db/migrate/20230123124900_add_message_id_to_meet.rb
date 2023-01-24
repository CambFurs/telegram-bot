class AddMessageIdToMeet < ActiveRecord::Migration[6.1]
  def change
    add_column :meets, :message_id, :integer
  end
end
