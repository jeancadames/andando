<?php

namespace App\Models;

use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

/**
 * Modelo principal de usuarios.
 *
 * En AndanDO este modelo representa tanto:
 * - Clientes
 * - Proveedores
 *
 * El campo `type` permite diferenciar el tipo de cuenta.
 */
class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasFactory, Notifiable, HasApiTokens;

    /**
     * Campos que se pueden asignar masivamente.
     *
     * IMPORTANTE:
     * Todo campo que queramos guardar usando create(), update()
     * o fill() debe estar aquí.
     */
    protected $fillable = [
        'name',
        'email',
        'password',
        'type',
        'phone',

        // Perfil del cliente
        'avatar_path',
        'birth_date',
        'gender',
        'nationality',
        'residence_city',
        'preferred_currency',
        'language',
        'country',
    ];

    /**
     * Campos ocultos al convertir el modelo a JSON.
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * Conversión automática de tipos.
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'birth_date' => 'date',
        ];
    }

    /**
     * Relación con el perfil de proveedor.
     */
    public function provider()
    {
        return $this->hasOne(Provider::class);
    }
}