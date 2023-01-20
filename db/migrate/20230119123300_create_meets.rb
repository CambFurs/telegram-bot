class CreateMeets < ActiveRecord::Migration[6.1]
  def change
    create_table :meets do |t|
      t.date :meet_date
      t.boolean :in_person
      t.string :location
      t.string :notes

      t.timestamps
    end
  end
end