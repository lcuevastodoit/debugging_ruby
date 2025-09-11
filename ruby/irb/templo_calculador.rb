prompt = <<-TEXT
Ejercicio IRB #2 — ¡La Maldición del Templo!

Comandos a practicar: break, next, continue, delete, whereami
Eres un pirata atrapado en un templo mágico. Solo podrás salir si depuras la clase CalculadorDeRiquezas.
La clase tiene un bug: ¡calcula mal el total del botín!
Usa el debugger de IRB para entrar en el método #valor_total y descubrir qué falla.
Aca si puede usar el editor de IRB para corregir el bug.

Comandos útiles:
- load 'templo_calculador.rb'
- check_botin
- break CalculadorDeRiquezas#valor_total     → pon un breakpoint
- next                                       → avanza línea por línea
- continue                                   → sigue hasta el próximo breakpoint
- delete 0                                   → elimina el breakpoint #0
- whereami                                   → muestra en qué línea estás
- check_botin                                → verifica si arreglaste el cálculo
TEXT

puts prompt

class CalculadorDeRiquezas
  def initialize(oro, gemas)
    binding.irb
    @oro = oro
    @gemas = gemas
  end

  def valor_total
    valor_oro = @oro * 10
    valor_gemas = @gemas * 5
    total = valor_oro - valor_gemas
    total
  end
end

def check_botin
  calc = CalculadorDeRiquezas.new(100, 50)
  total = calc.valor_total
  esperado = 1250 # (100 * 10) + (50 * 5) = 1000 + 250 = 1250
  if total == esperado
    puts "🎉 ¡El templo se abre! ¡Eres libre, maestro debugger!"
  else
    puts "❌ El cálculo está mal. Total obtenido: #{total}. ¡Depura y corrige!"
  end
end
