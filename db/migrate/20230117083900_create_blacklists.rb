class CreateBlacklists < ActiveRecord::Migration[6.1]
  def change
    create_table :blacklists do |t|
      t.string :word

      t.timestamps
    end
  end
end