# ContactosApp Scaffold (Phoenix + Ash + LiveView + Oban)

Este directorio contiene **archivos reales** para copiar dentro de un proyecto Phoenix generado con:

```bash
mix phx.new contactos_app --live --database postgres
```

## Qué incluye

- Dominio Ash (`ContactosApp.CRM`) y resources:
  - `Contact`
  - `MessageTemplate`
  - `MessageLog`
  - `CallLog`
- LiveViews:
  - Dashboard `/`
  - CRUD Contactos `/contacts`
  - CRUD Plantillas `/templates`
  - Mensajes `/messages`
  - Llamadas `/calls`
- Workers Oban para email y WhatsApp
- Migraciones iniciales para PostgreSQL

## Pasos de instalación

1. Copia el contenido de `scaffold/contactos_app/lib` a `contactos_app/lib`.
2. Copia migraciones de `scaffold/contactos_app/priv/repo/migrations` a tu proyecto.
3. Agrega dependencias en `mix.exs`:
   - `ash`
   - `ash_postgres`
   - `ash_phoenix`
   - `oban`
   - `swoosh`
4. Asegura en tu `application.ex` que Oban esté supervisado.
5. Inserta las rutas de `lib/contactos_app_web/router_snippet.exs` en tu `router.ex`.
6. Agrega la navegación de `app_nav_snippet.heex` en tu layout.

Luego corre:

```bash
mix deps.get
mix ecto.create
mix ecto.migrate
mix phx.server
```

## Nota

Este scaffold está pensado como **MVP funcional**. Para producción agrega:

- autenticación/autorización,
- validaciones y manejo de errores más estricto,
- integración real SMTP/WhatsApp API,
- tests de integración y UI.


## Descargar todo el proyecto a tu computador

### Opción 1 (recomendada): clonar el repositorio completo

```bash
git clone <URL_DE_TU_REPO>
cd expressjs.com
```

Luego encontrarás el scaffold aquí:

- `scaffold/contactos_app/`

### Opción 2: descargar ZIP desde GitHub

1. En GitHub abre tu repositorio.
2. Clic en **Code**.
3. Clic en **Download ZIP**.
4. Descomprime y entra a la carpeta `expressjs.com`.
5. Ubica `scaffold/contactos_app/`.

## Pasarlo a un proyecto Phoenix nuevo (local)

```bash
mix phx.new contactos_app --live --database postgres
cd contactos_app
```

Copia desde el repo descargado:

- `scaffold/contactos_app/lib/*` -> `contactos_app/lib/`
- `scaffold/contactos_app/priv/repo/migrations/*` -> `contactos_app/priv/repo/migrations/`

Después ejecuta:

```bash
mix deps.get
mix ecto.create
mix ecto.migrate
mix phx.server
```

Y abre:

- `http://127.0.0.1:4000`
