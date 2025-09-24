# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create Minecraft mobs for debugging exercises
minecraft_mobs = [
  {
    name: "Zombie",
    health: 20,
    attack: 3,
    defense: 0,
    description: "A hostile undead mob that spawns in dark areas and attacks players on sight."
  },
  {
    name: "Skeleton",
    health: 20,
    attack: 4,
    defense: 0,
    description: "A hostile mob that shoots arrows at players from a distance."
  },
  {
    name: "Creeper",
    health: 20,
    attack: 49,
    defense: 0,
    description: "A hostile mob that explodes when it gets close to players, destroying blocks."
  },
  {
    name: "Enderman",
    health: 40,
    attack: 7,
    defense: 0,
    description: "A neutral mob that teleports and becomes hostile when looked at directly."
  },
  {
    name: "Spider",
    health: 16,
    attack: 2,
    defense: 0,
    description: "A neutral mob that becomes hostile in dark areas and can climb walls."
  },
  {
    name: "Witch",
    health: 26,
    attack: 6,
    defense: 0,
    description: "A hostile mob that throws harmful potions at players."
  }
]

minecraft_mobs.each do |mob_data|
  Mob.find_or_create_by!(name: mob_data[:name]) do |mob|
    mob.health = mob_data[:health]
    mob.attack = mob_data[:attack]
    mob.defense = mob_data[:defense]
    mob.description = mob_data[:description]
  end
end

puts "Created #{Mob.count} Minecraft mobs for debugging exercises!"
