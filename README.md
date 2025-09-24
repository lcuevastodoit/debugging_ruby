
# Gamified Ruby Debugging Exercises
## Purpose
This repository contains exercises and games designed to practice advanced debugging techniques in Ruby using Pry, IRB, debug or byebug. Each scenario simulates situations where you must inspect, modify, and correct the state of objects and processes using debugging commands, without relying on external frameworks.

## How to Use
- Start a Pry or IRB session in your terminal.
- Load the main exercise file: `load 'pry/santuario_custodios.rb'` or the corresponding one.
- Use the recommended commands in the prompt e.g. (`watch`, `cd`, `ls`, `show-method`, `whereami`, etc.) to inspect and manipulate objects.
- The goal is to restore balance, decipher messages, or fix bugs using the fewest number of calls and following good debugging practices.

## License
This repository is for educational purposes and follows open-source principles.

_____

## 1. Ejercicio de Ruby Debugging gamificados
### Propósito
Este repositorio contiene ejercicios y juegos diseñados para practicar técnicas avanzadas de depuración en Ruby usando Pry, IRB, debug o byebug. Cada escenario simula situaciones donde debes inspeccionar, modificar y corregir el estado de objetos y procesos mediante comandos de depuración, sin depender de frameworks externos.

### Cómo usar
- Inicia una sesión de Pry o IRB en tu terminal.
- Carga el archivo principal del ejercicio: `load 'pry/santuario_custodios.rb'` o el que corresponda.
- Utiliza los comandos recomendados en el prompt e.g. (`watch`, `cd`, `ls`, `show-method`, `whereami`, etc.) para inspeccionar y manipular los objetos.
- El objetivo es restaurar el equilibrio, descifrar mensajes o corregir bugs usando la menor cantidad de llamadas y siguiendo buenas prácticas de depuración.

### Licencia
Este repositorio es para fines educativos y sigue principios de código abierto.

## 2. RAILS DEBUGGING APP
### Propósito
Este repositorio contiene una aplicación Rails CRUD sencilla con bootstrap y webpacker, configurada para practicar técnicas de depuración en un entorno web. Incluye algunos errores sencillos de depuración para que puedas practicar.

### URLs de prueba disponibles:

http://localhost:3000 - Lista de mobs de minecraft
http://localhost:3000/mobs/1 - Detalle de mob
http://localhost:3000/mobs/debug_error - Para probar manejo de errores
http://localhost:3000/mobs?debug_partial=true - Para debugging en parciales

### Preparación Inicial
1. Clonar o crear la aplicación
cd rails_app

2. Instalar dependencias
bundle install

3. Ejecutar setup de base de datos
rails db:create db:migrate db:seed

4. Iniciar app de rails
bin/dev

5. Iniciar rails y webpack por separado
rails server
bin/webpack-dev-server
