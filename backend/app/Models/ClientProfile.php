<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Modelo ClientProfile.
 *
 * Representa los datos específicos del perfil de un cliente.
 *
 * No debe manejar autenticación, contraseña ni email.
 * Eso pertenece al modelo User.
 */
class ClientProfile extends Model
{
    use HasFactory;

    /**
     * Nombre de la tabla asociada al modelo.
     */
    protected $table = 'client_profiles';

    /**
     * Campos que pueden ser asignados masivamente.
     */
    protected $fillable = [
        'user_id',
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
     * Conversión automática de tipos.
     */
    protected $casts = [
        'birth_date' => 'date',
    ];

    /**
     * Relación inversa con User.
     *
     * Un perfil de cliente pertenece a un usuario.
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}