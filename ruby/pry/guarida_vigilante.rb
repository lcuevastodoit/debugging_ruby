prompt = <<-TEXT
Ejercicio Pry #1 — ¡La Guarida del Vigilante!

Comandos a practicar: load, watch, cd, ls del REPL Pry
Eres un pirata en la Guarida del Vigilante, donde los valores cambian misteriosamente.

⚠️ DEBES USAR PRY como REPL principal
→ En tu terminal: pry

Comandos útiles:
- load 'guarida_vigilante.rb'
- watch @tesoro.oro
- watch: @tesoro.maldicion
- cd @tesoro                      → navega al contexto del objeto
- ls                              → lista métodos y variables del objeto actual
- modifica el tesoro con los métodos disponibles hasta que la maldición se desactive
TEXT

puts prompt

class TesoroMaldito
  attr_accessor :oro, :maldicion

  def initialize(oro = 100, maldicion = false)
    @oro = oro
    @maldicion = maldicion
    verificar_maldicion
  end

  def agregar_oro(cantidad)
    @oro += cantidad
    verificar_maldicion
  end

  def quitar_oro(cantidad)
    @oro -= cantidad
    verificar_maldicion
  end

  def verificar_maldicion
    # Activa la maldición si el oro excede 500
    if @oro < 500
      @maldicion = true
    else
      @maldicion = false
    end
  end

  def valor_real
    @maldicion ? (@oro / 2) : @oro
  end
end

def setup_vigilancia
  @tesoro = TesoroMaldito.new
  puts "¡Tesoro inicializado con #{@tesoro.oro} monedas!"
end

def check_vigilancia
  if @tesoro.maldicion
    puts "¡Cuidado! El tesoro está bajo maldición. Valor real: #{@tesoro.valor_real}"
  else
    puts "Tesoro seguro. Valor real: #{@tesoro.valor_real}"
  end
end
setup_vigilancia