prompt = <<-TEXT
Ejercicio IRB # 1

Comandos a practicar en IRB: load, private_methods, edit
Eres un joven pirata informático que ha encontrado un mapa del tesoro...
...¡pero está cifrado en código Ruby! Para descifrarlo, debes usar solo tu fiel terminal
y la herramienta IRB (Interactive Ruby). No hay Rails, no hay gemas mágicas — solo tú,
tu intuición y el REPL más clásico de Ruby.

El mapa está compuesto por 3 pistas. Cada pista es una parte del mensaje.
Tu misión es resolver el mensaje_final desde IRB pero sin editar el codigo fuente orginal.

comandos utiles:
- load
- private_methods.grep /<regex>/
- edit
- check_result
TEXT

puts prompt
def pista1
  "¡El tesoro está en la isla de"
end

def pista2
  " los monos saltarines!"
end

def pista3
  pista1 + pista2
end

def mensaje_final
  pista3.reverse
end

def check_result
  if mensaje_final == "¡El tesoro está en la isla de los monos saltarines!"
    puts "¡Felicidades, has descifrado el mapa del tesoro!"
  else
    puts "El mensaje_final no es correcto. Sigue intentando."
  end
end
