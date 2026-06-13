# Panel administrativo AndanDO (Inertia + Vue 3 + TypeScript)

Panel interno para 3 administradores. Se conecta a **tu misma base de datos y
tablas existentes** (`users`, `providers`, `provider_verification_requests`,
`provider_documents`, `booking_claims`, `provider_experiences`, etc.). No incluye
migraciones nuevas ni toca tu API móvil de Sanctum: usa sesión web (guard `web`),
que es lo estándar con Inertia.

## Qué hace

- **Login solo por ruta** (`/admin/login`), sin registro. Los 3 admins se crean con un seeder.
- **Afiliados**: lista solicitudes de verificación, ve el detalle y los documentos privados, aprueba o rechaza.
- **Reclamos**: lista los `booking_claims`, ve la reserva asociada, marca resuelto o rechazado.
- **Experiencias**: lista/busca, y permite desactivar/activar o rechazar una experiencia.

---

## 1. Copiar archivos

Copia el contenido de este paquete sobre tu proyecto Laravel respetando las rutas
(`app/...`, `resources/js/...`, `database/seeders/...`). El bloque de rutas de
`routes/web.php` debes **pegarlo dentro de tu `routes/web.php` actual** (no lo
sobrescribas si ya tienes el landing ahí).

## 2. Dependencias de Composer

```bash
composer require inertiajs/inertia-laravel
```

Si **no** tienes aún el middleware de Inertia, genéralo (luego reemplaza su
contenido con el `HandleInertiaRequests.php` incluido, que ya comparte `auth` y `flash`):

```bash
php artisan inertia:middleware
```

## 3. Dependencias de Node

```bash
npm install -D @vitejs/plugin-vue @tailwindcss/vite typescript vue-tsc @types/node
npm install @inertiajs/vue3 vue
```

> El proyecto usa **Tailwind v4** (plugin `@tailwindcss/vite`). Si estás en
> Tailwind v3, cambia en `resources/css/app.css` el `@import 'tailwindcss';`
> por las directivas `@tailwind base; @tailwind components; @tailwind utilities;`
> y usa el plugin de PostCSS en lugar del de Vite.

## 4. Registrar middleware (bootstrap/app.php)

En Laravel 11+/12+/13 los middleware se registran en `bootstrap/app.php`:

```php
->withMiddleware(function (Middleware $middleware) {
    // Inertia en el grupo web
    $middleware->web(append: [
        \App\Http\Middleware\HandleInertiaRequests::class,
    ]);

    // Alias para proteger el panel
    $middleware->alias([
        'admin' => \App\Http\Middleware\EnsureUserIsAdmin::class,
    ]);

    // Cuando un invitado entra a una ruta protegida, lo mandamos al login del panel.
    $middleware->redirectGuestsTo(fn () => route('admin.login'));
})
```

> Si tu landing público también requiere redirección de invitados a otro lado,
> ajusta `redirectGuestsTo` con una condición por ruta.

## 5. Crear los administradores

Edita correos y contraseñas en `database/seeders/AdminUserSeeder.php` y ejecuta:

```bash
php artisan db:seed --class=AdminUserSeeder
```

Esto crea/actualiza 3 usuarios con `type = 'admin'`. Solo usuarios con ese tipo
pueden entrar (el login fuerza `type => 'admin'`).

## 6. Compilar y probar

```bash
npm run dev      # desarrollo
# o
npm run build    # producción
```

Entra a `http://tu-app.test/admin/login`.

---

## Notas importantes

**Documentos privados.** El controlador `DocumentController` sirve los archivos
desde `provider_documents.disk` (por defecto `private`/`local`). Verifica que ese
disco exista en `config/filesystems.php`. La ruta `/admin/documentos/{id}` está
protegida por el middleware `admin`, así que los documentos nunca quedan públicos.

**Fotos de experiencias.** En `Experiences/Show.vue` las imágenes se cargan desde
`/api/public-files/{path}` porque así lo expone tu modelo (`getPhotoUrlAttribute`).
Si esa ruta vive en otro lugar, ajústala.

**Cambiar la URL del panel.** Si quieres una ruta menos obvia, cambia el `prefix('admin')`
en el bloque de rutas (ej. `prefix('panel-andando')`) y los `href` en
`resources/js/Layouts/AdminLayout.vue` y en las páginas.

**Verificación de admin.** Para distinguir admins se usa la columna `users.type`
que ya existe en tu migración. No se agregó nada nuevo.

## Estructura entregada

```
app/Http/Controllers/Admin/
    AuthController.php
    DashboardController.php
    VerificationRequestController.php   (afiliados)
    DocumentController.php              (sirve documentos privados)
    ClaimController.php                 (reclamos)
    ExperienceController.php
app/Http/Middleware/
    EnsureUserIsAdmin.php
    HandleInertiaRequests.php
database/seeders/AdminUserSeeder.php
routes/web.php                          (pegar dentro del tuyo)
resources/views/app.blade.php
resources/css/app.css
resources/js/
    app.ts
    lib/format.ts
    types/index.d.ts, vue-shims.d.ts
    Layouts/AdminLayout.vue
    Components/StatusBadge.vue, Pagination.vue, ConfirmModal.vue
    Pages/Auth/Login.vue
    Pages/Dashboard.vue
    Pages/Affiliates/Index.vue, Show.vue
    Pages/Claims/Index.vue, Show.vue
    Pages/Experiences/Index.vue, Show.vue
vite.config.ts
tsconfig.json
```
