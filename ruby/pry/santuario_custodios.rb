prompt = <<-TEXT
Ejercicio Pry #2 (Avanzado) - El Santuario de los Custodios

Comandos a practicar: load, watch, cd, ls, whereami, show-method del REPL Pry
Eres un investigador arcano atrapado en el Santuario de los Custodios, donde los artefactos antiguos
corrompen a quienes intentan dominarlos.

⚠️ DEBES USAR PRY como REPL principal
→ En tu terminal: pry

Comandos útiles:
- load 'santuario_custodios.rb'
- watch @custodio.estado
- watch @artefacto.energia
- cd @custodio                        → navega al contexto del personaje
- ls                                  → lista métodos y variables del objeto actual
- show-method
- whereami

Objetivo:
— Purificar el artefacto o equilibrar la energía del Custodio. Usando solo los métodos disponibles,
navega y averigua cómo interactuar con el artefacto y que valores necesitas aumentar o disminuir
usando la menor cantidad de llamadas a los metodos del artefacto y/o el Custodio
hasta que el estado de corrupción desaparezca.
TEXT

puts prompt

class Artefacto
  attr_accessor :nombre, :energia, :corrupto

  def initialize(nombre, energia = nil)
    @nombre = nombre
    @energia = energia || random_initial_energy
    @corrupto = true
    verificar_estado
  end

  def random_initial_energy
    range1 = (1..1999).to_a
    range2 = (2101..9999).to_a
    (range1 + range2).sample
  end

  def absorber(cantidad)
    @energia += cantidad
    verificar_estado
  end

  def consumir(cantidad)
    @energia -= cantidad
    verificar_estado
  end

  def purificar
    @energia = @energia / 2
    verificar_estado
  end

  def verificar_estado
    if @energia >= 2000 && @energia <= 2100
      @corrupto = false
    else
      @corrupto = true
    end
  end
end

class Custodio
  attr_accessor :nombre, :estado, :artefacto

  def initialize(nombre, artefacto)
    @nombre = nombre
    @artefacto = artefacto
    @estado = :corrompido
    verificar_estado
  end

  def invocar_reliquia
    verificar_estado
  end

  def liberar
    if @estado == :corrompido
      @artefacto.purificar
      verificar_estado
    end
  end

  def verificar_estado
    @estado = @artefacto.corrupto ? :corrompido : :equilibrado
  end

  def descripcion
    "Custodio #{@nombre}, estado: #{@estado}, con artefacto #{@artefacto.nombre} (energía: #{@artefacto.energia})"
  end
end

def setup_santuario
  @artefacto = Artefacto.new("Corona del Eclipse", nil)
  @custodio  = Custodio.new("Erevan, Guardián del Umbral", @artefacto)
  puts "Has despertado en el Santuario. Frente a ti está #{@custodio.descripcion}"
end

def check_santuario
  if @custodio.estado == :corrompido
    puts "⚠️ El Custodio está bajo corrupción. El artefacto mantiene energía inestable."
  else
    puts "✔️ El equilibrio ha sido restaurado. El artefacto ya no amenaza el santuario."
  end
end

setup_santuario
