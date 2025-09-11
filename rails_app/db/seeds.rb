User.destroy_all
Post.destroy_all

puts "Creating users..."

users = [
  { name: "Juan Pérez", email: "juan@example.com", active: true },
  { name: "María García", email: "maria@example.com", active: true },
  { name: "Carlos López", email: "carlos@example.com", active: false },
  { name: "Ana Martínez", email: "ana@example.com", active: true }
]

created_users = users.map do |user_data|
  User.create!(user_data)
end

puts "Creating posts..."

posts_data = [
  { title: "Mi primer post", content: "Este es el contenido de mi primer post en el blog.", published: true },
  { title: "Debugging en Rails", content: "Técnicas avanzadas para hacer debugging en aplicaciones Rails.", published: true },
  { title: "Draft post", content: "Este es un borrador que aún no está publicado.", published: false },
  { title: "Performance Tips", content: "Consejos para mejorar el rendimiento de tu aplicación Rails.", published: true },
  { title: "Testing Strategies", content: "Estrategias efectivas para testing en Ruby on Rails.", published: false }
]

created_users.each do |user|
  posts_data.sample(rand(1..3)).each do |post_data|
    user.posts.create!(post_data)
  end
end

puts "Created #{User.count} users and #{Post.count} posts"
