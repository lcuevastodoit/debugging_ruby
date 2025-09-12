# 🎮 Debugging Game - Ejercicio Gamificado para Rails

## 📋 Objetivo Principal

Crear un mini-juego interactivo donde los usuarios resuelvan retos de debugging utilizando herramientas como **Pry**, **debug**, **byebug** o **irb** desde la terminal o breakpoints. Un servicio en segundo plano con **Sidekiq** supervisará en tiempo real los logs de la consola, detectando comandos y respuestas que validan el progreso del usuario. Al completar cada reto, la aplicación mostrará el progreso y logros en una página dedicada.

---

## 🏗️ Arquitectura del Sistema

### 🔧 Servicio de Monitoreo (Sidekiq)

El servicio de background debe leer los logs generados por consolas interactivas usando las siguientes técnicas en tiempo real de froma simultanea para las cuatro herramientas de debugging o REPL usando (ordenadas por preferencia):

1. **Concurrent Ruby** - Para procesamiento asíncrono eficiente
2. **Open3/Popen3** - Para ejecutar `cat -f` y leer STDOUT en tiempo real
3. **File monitoring** - Alternativa robusta y performante

### 📂 Ubicaciones de Logs (macOS)

| Herramienta | Ubicación del Log |
|-------------|-------------------|
| **Pry** | `~/.local/share/pry/pry_history` |
| **debug** | `~/.local/state/rdbg/history` |
| **IRB** | `~/.irb_history` |
| **byebug** | `~/.byebug_history` |
| **Rails** | `rails-app/log/development.log` |

### 🔒 Consideraciones de Seguridad

- Validar existencia y permisos de acceso a archivos de log

---

## 🎯 Sistema de Objetivos

### 📄 Configuración YAML

Los objetivos se definen en un archivo YAML accesible desde la gema `settings`. Incluye operaciones CRUD sobre modelos `User` y `Post`, más comandos específicos de debugging.

**Mínimo requerido: 16 objetivos, 2 x nivel**

#### Ejemplo de Objetivo

```yaml
debugging_game:
  objectives:
    - key: "rookie_inspect_user"
      title: "Rookie - Inspect User"
      description: "Use Pry for this example"
      expected_commands:
        - "User.new"
        - "save"
        - "p @user"
        - "@user.inspect"
        - "puts @user.inspect"
      points: 100
      level: "rookie"
      problem: "Create a new User and find what data is stored in the @user variable"
      hints:
        - "Try using User.new to create a new instance"
        - "Use .inspect to see the object's internal state"
      time_limit: 300
      prerequisites: [] # other objective keys required
```

### 🎮 Tipos de Objetivos Sugeridos

#### Por Herramienta
- **Pry**: Navegación de código, breakpoints, exploración de objetos
- **IRB**: Evaluación de expresiones, testing rápido
- **debug**: Step debugging, inspección de variables
- **byebug**: Debugging avanzado, call stack

#### Por Dificultad
- **Rookie**: Comandos básicos (`p`, `puts`, `inspect`)
- **Magician**: Navegación (`ls`, `cd`, `show-method`)
- **Sorcerer**: Breakpoints y stepping (`break`, `step`, `next`)
- **Hero**: Debugging complejo (`backtrace`, `up`, `down`)
- **Expert**: Performance y optimización (comandos de depuracion relacionados)
- **Astro**: Metaprogramming y introspección (comandos de depuracion relacionados)
- **Star**: Debugging en producción (comandos de depuracion relacionados)
- **Final Boss**: Retos combinados y casos edge (comandos de depuracion relacionados)

---

## 🖥️ Interfaz de Usuario

### 📊 Vista "Debugging Game" 

**Componentes principales:**
- **Tabla de retos** con estado visual (✅ completado, 🔄 en progreso, 🔒 bloqueado)
- **Barra de progreso** general y por nivel
- **Sistema de logros** con emojis y títulos por nivel
- **Puntuación en tiempo real**
- **Timer** para objetivos con límite de tiempo

### ⚡ Tecnología: Hotwire

**Toda la vista debe ser reactiva usando Hotwire:**
- **Turbo Streams** para actualizaciones en tiempo real
- **Stimulus controllers** para interactividad
- **Turbo Frames** para carga de contenido dinámico

### 🎨 Elementos de Gamificación

#### Niveles y Emojis
| Nivel | Emoji | Título |
|-------|-------|--------|
| rookie | 🐣 | Novato |
| magician | 🎩 | Mago |
| sorcerer | 🔮 | Hechicero |
| hero | 🦸 | Héroe |
| expert | 🎯 | Experto |
| astro | 🚀 | Astronauta |
| star | ⭐ | Estrella |
| final boss | 👑 | Jefe Final |

---

## 🎮 Mecánicas del Juego

### 🔓 Sistema de Desbloqueo

- **Progresión lineal**: Los niveles se desbloquean secuencialmente
- **Prerequisitos**: Algunos objetivos requieren completar otros primero
- **Puntos mínimos**: Cada nivel requiere una puntuación mínima

### 🏆 Sistema de Puntuación

#### Factores de Puntuación
- **Puntos base** del objetivo
- **Bonus por tiempo** (si se completa rápidamente)
- **Penalización por ayudas** (si se usan hints)
- **Bonus por racha** (objetivos consecutivos sin errores)

#### Multiplicadores
```yaml
time_bonus:
  under_50_percent: 1.5x
  under_25_percent: 2.0x
streak_bonus:
  5_consecutive: 1.2x
  10_consecutive: 1.5x
  perfect_level: 2.0x
```

---

## 👤 Gestión de Jugadores

### 📝 Perfil de Usuario

**Campos requeridos:**
- Nombre o alias del jugador
- Puntuación máxima alcanzada
- Nivel actual
- Fecha de último acceso

### 🏅 Tabla de Clasificación

**Funcionalidades:**
- **Ranking global** por puntuación total
- **Ranking por nivel** alcanzado


### 📈 Métricas y Analytics

```yaml
user_stats:
  - total_points
  - current_level
  - objectives_completed
  - average_completion_time
  - favorite_debugging_tool
  - longest_streak
  - hints_used
  - resets_count
```

---

## 🔄 Funcionalidades del Sistema

### 🗑️ Reset del Juego

**Botón de reset que:**
- Borra todos los logs de herramientas de debugging
- Reinicia progreso del usuario actual
- Mantiene estadísticas históricas
- Confirma acción con modal de seguridad

### 📊 Monitoreo y Logs

#### Sistema de Logs Interno
- **Errores del sistema**: Fallos en lectura de logs, timeouts

### 🔧 Panel de Administración

**Funcionalidades administrativas:**
- **Mantenimiento**: Limpiar logs, reiniciar servicios

---

## ⚡ Optimizaciones de Performance


### 📡 Background Jobs

- **Log processing**: Jobs asíncronos para procesar logs grandes
- **Score calculation**: Cálculo diferido de puntuaciones complejas
- **Cleanup tasks**: Limpieza periódica de logs antiguos
---

## 🚀 Roadmap de Implementación

### Fase 1: MVP
- [ ] Validar si existen los Modelos de datos básico (User, Post, GameProgress) y sino crearlos, migraciones, modelo y CRUD
- [ ] Lectura simultánea en tiempo real de logs de las 4 herramientas (Pry, debug, IRB, byebug)
- [ ] Validación de comandos y detección de progreso
- [ ] UI básica con Hotwire para mostrar progreso

### Fase 2: Core Game
- [ ] Sistema de puntos y niveles (8 niveles, 2 objetivos por nivel = 16 total)
- [ ] Implementación de objetivos CRUD sobre User y Post en el YAML
- [ ] Definir objetivos en el YAML sobre depuracion usando las herramientas de debugging
- [ ] Progresión secuencial de niveles con desbloqueo
- [ ] Tabla de clasificación básica (ranking global y por nivel)

### Fase 3: Polish
- [ ] Sistema de reset completo con limpieza de logs
- [ ] Gestión de jugadores (alias, puntuación máxima, historial)
- [ ] Background jobs para procesamiento de logs grandes
- [ ] Interfaz reactiva completa con Turbo Streams

## IA tips
-  Puedes usar comandos como curl, cat, ls, Rails.runner, ruby, irb, pry y otros desde el terminal para ir confirmando el estado y progreso de los cambios.

---

## 📚 Recursos Adicionales

### 🔗 Enlaces Útiles
- [Pry Documentation](https://deepwiki.com/pry/pry)
- [Byebug Documentation](https://deepwiki.com/deivid-rodriguez/byebug)
- [Ruby Debug Documentation](https://deepwiki.com/ruby/debug)
- [IRB Documentation](https://deepwiki.com/ruby/irb)
- [Hotwire Turbo](https://turbo.hotwired.dev/)
- [Sidekiq Best Practices](https://github.com/sidekiq/sidekiq/wiki/Best-Practices)
