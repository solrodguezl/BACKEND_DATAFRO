# Backend Datafro

API REST para autenticación y gestión de usuarios.

## Requisitos

- Node.js
- PostgreSQL
- Variables de entorno configuradas en un archivo `.env`

## Ejecutar el proyecto

```bash
npm install
npm run dev
```

La API queda disponible en:

```bash
http://localhost:3000
```

## Endpoints disponibles

### Health check

```http
GET /health
```

Respuesta:

```json
{
  "status": "ok"
}
```

---

## Autenticación

### 1) Login

```http
POST /api/auth/login
```

Body:

```json
{
  "documento": "12345678",
  "clave": "miPassword123"
}
```

Respuesta esperada:

```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "usuario": {
    "id": "a23f6240-1b38-49eb-ab57-4f412d655118",
    "documento": "12345678",
    "activo": true
  }
}
```

> El `accessToken` se usa en el header `Authorization` para rutas protegidas.

### 2) Refresh token

```http
POST /api/auth/refresh
```

Body:

```json
{
  "refreshToken": "<refreshToken>"
}
```

Respuesta:

```json
{
  "accessToken": "<nuevo_access_token>"
}
```

### 3) Logout

```http
POST /api/auth/logout
```

Body:

```json
{
  "refreshToken": "<refreshToken>"
}
```

Respuesta esperada:

```json
{
  "mensaje": "Sesión cerrada correctamente"
}
```

Cuando haces logout, la sesión activa del usuario queda revocada y el access token ya no será válido para rutas protegidas.

---

## Usuarios

Todas las rutas de usuarios requieren autenticación, excepto `POST /api/usuarios`.

### Header requerido

```http
Authorization: Bearer <accessToken>
```

### 1) Crear usuario

```http
POST /api/usuarios
```

Body:

```json
{
  "documento": "12345678",
  "clave": "miPassword123"
}
```

Respuesta:

```json
{
  "id_usuario": "a23f6240-1b38-49eb-ab57-4f412d655118",
  "documento": "12345678",
  "activo": true,
  "fecha_creacion": "2026-09-11T12:00:00.000Z",
  "fecha_actualizacion": "2026-09-11T12:00:00.000Z"
}
```

### 2) Obtener todos los usuarios

```http
GET /api/usuarios
```

Respuesta:

```json
[
  {
    "id_usuario": "a23f6240-1b38-49eb-ab57-4f412d655118",
    "documento": "12345678",
    "activo": true,
    "fecha_creacion": "2026-09-11T12:00:00.000Z",
    "fecha_actualizacion": "2026-09-11T12:00:00.000Z"
  }
]
```

### 3) Obtener usuario por id

```http
GET /api/usuarios/:id
```

Ejemplo:

```http
GET /api/usuarios/a23f6240-1b38-49eb-ab57-4f412d655118
```

### 4) Actualizar usuario

```http
PUT /api/usuarios/:id
```

Ejemplo:

```http
PUT /api/usuarios/a23f6240-1b38-49eb-ab57-4f412d655118
```

Body:

```json
{
  "activo": false
}
```

También puede enviarse el id en el body:

```json
{
  "id": "a23f6240-1b38-49eb-ab57-4f412d655118",
  "activo": false
}
```

### 5) Eliminar usuario

```http
DELETE /api/usuarios/:id
```

Ejemplo:

```http
DELETE /api/usuarios/a23f6240-1b38-49eb-ab57-4f412d655118
```

Respuesta esperada:

```json
{
  "mensaje": "Usuario eliminado correctamente",
  "id": "a23f6240-1b38-49eb-ab57-4f412d655118"
}
```

---

## Ejemplo con curl

### Login

```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "documento": "12345678",
    "clave": "miPassword123"
  }'
```

### Obtener usuarios protegidos

```bash
curl -X GET http://localhost:3000/api/usuarios \
  -H "Authorization: Bearer <accessToken>"
```

### Actualizar usuario

```bash
curl -X PUT http://localhost:3000/api/usuarios/a23f6240-1b38-49eb-ab57-4f412d655118 \
  -H "Authorization: Bearer <accessToken>" \
  -H "Content-Type: application/json" \
  -d '{
    "activo": true
  }'
```

### Logout

```bash
curl -X POST http://localhost:3000/api/auth/logout \
  -H "Content-Type: application/json" \
  -d '{
    "refreshToken": "<refreshToken>"
  }'
```

---

## Sincronización offline (app móvil)

La app (ASISTIR_2026) puede trabajar **sin internet**. Cuando no hay conexión
guarda en el teléfono lo que el usuario registra y lo envía a esta API cuando
vuelve la red. Para que esos reenvíos sean seguros, el backend tiene tres
cambios.

### 1) Header `Idempotency-Key` (evita duplicados)

Si la conexión se corta justo después de que el servidor guardó, pero antes de
que la respuesta llegue al teléfono, la app vuelve a enviar lo mismo. Para que
eso no cree registros repetidos, cada envío lleva un UUID único:

```http
POST /api/actividades/:id/asistencias
Authorization: Bearer <accessToken>
Idempotency-Key: 0b6f0a8e-3c1d-4f1e-9a54-2d8f3a7c9e10
```

- La **primera vez** la petición se ejecuta normal y, si sale bien (2xx), se
  guarda su respuesta en la tabla `operacion_idempotente`.
- Si llega **otra vez con la misma clave** (del mismo usuario), no se vuelve a
  ejecutar: se devuelve la respuesta guardada con el header
  `Idempotent-Replay: true`.
- **Sin el header** todo funciona igual que antes.

Rutas que lo aceptan:

| Método | Ruta | Qué hace |
|---|---|---|
| `POST` | `/api/actividades` | Crear actividad |
| `POST` | `/api/actividades/:id/asistencias` | Registrar asistencia |
| `POST` | `/api/caracterizacion` | Guardar capítulo de caracterización |

Las claves se borran a los 60 días.

### 2) Crear actividad con un id generado en el teléfono

Una actividad creada sin conexión necesita su id desde el principio, porque las
asistencias que se registran en ella (también offline) ya lo usan. Por eso
`POST /api/actividades` acepta un `id` opcional:

```json
{
  "id": "5f1c2b8a-7d3e-4a9b-8c21-0e6f4d2a1b37",
  "nombre": "Jornada de Salud",
  "fecha": "2026-11-26",
  "barrio": "El Salado"
}
```

Si ese id ya existe en la misma organización, se devuelve la actividad existente
(no se duplica). Si no se envía `id`, el servidor lo genera como siempre.

### 3) Hora real de la asistencia

`POST /api/actividades/:id/asistencias` acepta `fechaRegistro` opcional
(fecha ISO 8601). Así, una asistencia tomada sin conexión queda con la hora en
que realmente se registró y no con la hora en que se sincronizó. Nunca se
acepta una fecha en el futuro.

```json
{
  "documento": "1033456789",
  "nombres": "Ana Pérez",
  "etnia": "Afrocolombiana",
  "edad": 30,
  "genero": "Mujer",
  "barrio": "El Salado",
  "fechaRegistro": "2026-11-26T10:15:00-05:00"
}
```

### Migración

Crea la tabla `operacion_idempotente`. Se puede ejecutar más de una vez sin
problema:

```bash
npm run migrate          # corre todos los scripts, incluido sync_offline.sql
```

O solo este script, desde el SQL Editor de Neon:
[`database/sync_offline.sql`](database/sync_offline.sql).

> **Orden de despliegue:** despliega este backend **antes** que la nueva
> versión de la app. El backend anterior rechaza el campo `id` al crear
> actividades.

---

## Manejo de errores

La API responde con JSON en caso de errores, por ejemplo:

```json
{
  "error": "Token inválido o expirado"
}
```

O cuando hay validaciones:

```json
{
  "error": "Hay errores en los datos enviados",
  "details": [
    {
      "campo": "id",
      "mensaje": "Invalid UUID"
    }
  ]
}
```

## Notas

- Los ids de usuarios se manejan como UUID.
- La autenticación funciona con JWT.
- Los refresh tokens se guardan y validan en la base de datos.
- El logout revoca la sesión activa del usuario y deja inválido el access token asociado.
- Las rutas protegidas requieren `Authorization: Bearer <accessToken>`.
- Las escrituras que vienen de la cola offline de la app llevan `Idempotency-Key` (ver *Sincronización offline*).
