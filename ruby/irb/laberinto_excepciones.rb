prompt = <<-TEXT
Ejercicio IRB #3 — ¡El Laberinto de las Excepciones!

Comandos a practicar: step, frame, up, down, backtrace
Eres un pirata en el corazón del templo. Tres clases mágicas están lanzando errores.
Tu misión: usar el debugger para navegar entre frames y encontrar la raíz del problema.
Pista: solo descomenta las 2 lineas correctas para arreglar el bug.


Comandos útiles:
- load 'laberinto_excepciones.rb'
- entrar_al_laberinto
- next                                       → avanza línea por línea
- step                                       → entra paso a paso en llamadas de método
- frame                                      → muestra el frame actual
- up                                         → sube un nivel en el stack
- down                                       → baja un nivel en el stack
- backtrace                                  → muestra todo el stack trace
- edit Clase#metodo                          → edita o ve el codigo fuente de un método específico
- check_laberinto                            → verifica si resolviste el laberinto

⚠️ Este ejercicio lanza una excepción intencional. ¡Usa el debugger para atraparla y arreglarla!
Luego de arreglarlo, llama a `check_laberinto` para verificar tu solución.
TEXT

puts prompt

class GuardianDelTemplo
  def initialize(nombre)
    @nombre = nombre
  end

  def saludar(visitante)
    "#{@nombre} dice: Bienvenido, #{visitante}"
  end
end

class CalculadorDeOfrendas
  def self.calcular(ofrendas)
    # return if ofrendas.nil?
    # Bug intencional: ofrendas puede ser nil
    total = ofrendas.reduce(0) { |sum, valor| sum + valor }
    total
  end
end

class PortalDelTemplo
  def initialize(guardian)
    @guardian = guardian
  end

  def activar_portal(ofrendas)
    mensaje = @guardian.saludar("aventurero")
    puts mensaje

    total = CalculadorDeOfrendas.calcular(ofrendas)
    # total = 0 if total.nil?

    if total > 2099
      "Portal abierto: #{total} ofrendas aceptadas"
    else
      raise "Ofrendas insuficientes: solo #{total}"
    end
  end
end

# Punto de entrada con debugger activo
def entrar_al_laberinto(ofrendas = nil)
  # ¡Aquí se activa el debugger!
  binding.irb
  guardian = GuardianDelTemplo.new("Anciano K'Tul")
  portal = PortalDelTemplo.new(guardian)
  resultado = portal.activar_portal(ofrendas)
  puts resultado
rescue => e
  puts "💥 Excepción atrapada: #{e.message}"
end

def check_laberinto(ofrendas = nil)
  begin
    entrar_al_laberinto(ofrendas)
    puts "🎉 ¡Y has abierto el portal!"
  rescue
    puts "❌ El laberinto sigue sin resolverse. ¡Sigue intentando!"
  end
end