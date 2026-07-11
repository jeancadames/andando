<?php

namespace App\Models;

use App\Notifications\Auth\PasswordResetNotification;

use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
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

        //firebase google auth
        'firebase_uid',
        'avatar_url',
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
        ];
    }

    /**
     * Relación con el perfil de proveedor.
     */
    public function provider()
    {
        return $this->hasOne(Provider::class);
    }

    /**
     * Relación con el perfil de cliente.
     *
     * Un usuario puede tener un perfil de cliente.
     */
    public function clientProfile(): HasOne
    {
        return $this->hasOne(ClientProfile::class);
    }

    public function customerConversations(): HasMany
    {
        return $this->hasMany(Conversation::class, 'customer_user_id');
    }

    public function conversationMessages(): HasMany
    {
        return $this->hasMany(ConversationMessage::class, 'sender_user_id');
    }

    public function deviceTokens(): HasMany
    {
        return $this->hasMany(DeviceToken::class);
    }

    public function notificationPreference(): HasOne
    {
        return $this->hasOne(UserNotificationPreference::class);
    }

    public function sendPasswordResetNotification($token): void
    {
        $this->notify(new PasswordResetNotification($token));
    }
}