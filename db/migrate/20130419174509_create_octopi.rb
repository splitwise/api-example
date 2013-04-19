class CreateOctopi < ActiveRecord::Migration
  def change
    create_table :octopi do |t|

      t.timestamps
    end
  end
end
