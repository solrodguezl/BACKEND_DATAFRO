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
