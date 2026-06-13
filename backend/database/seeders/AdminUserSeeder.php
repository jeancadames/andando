<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

/**
 * Crea los usuarios administradores del panel.
 *
 * No hay registro público: estos 3 usuarios son los únicos que
 * pueden entrar al panel. Cambia los correos y contraseñas antes
 * de correrlo en producción.
 *
 * Ejecutar:
 *   php artisan db:seed --class=AdminUserSeeder
 */
class AdminUserSeeder extends Seeder
{
    public function run(): void
    {
        $admins = [
            [
                'name' => 'Jean Adames',
                'email' => 'jeancadames22@gmail.com',
                'password' => 'CambiaEstaClave1!',
            ],
            [
                'name' => 'Kevin Brea',
                'email' => 'kevinbreamon@gmail.com',
                'password' => 'CambiaEstaClave2!',
            ],
            [
                'name' => 'Adrian Contreras',
                'email' => 'adricontrerasgo@gmail.com',
                'password' => 'CambiaEstaClave3!',
            ],
        ];

        foreach ($admins as $admin) {
            User::updateOrCreate(
                ['email' => $admin['email']],
                [
                    'name' => $admin['name'],
                    'password' => Hash::make($admin['password']),
                    'type' => 'admin',
                    'email_verified_at' => now(),
                ]
            );
        }
    }
}
