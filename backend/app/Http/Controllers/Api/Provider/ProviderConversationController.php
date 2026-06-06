<?php

namespace App\Http\Controllers\Api\Provider;

use App\Http\Controllers\Controller;
use App\Models\Conversation;
use App\Models\ConversationMessage;
use App\Models\ProviderExperience;
use App\Services\PushNotificationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ProviderConversationController extends Controller
{
    public function __construct(
        private readonly PushNotificationService $pushNotificationService,
    ) {
    }

    public function index(Request $request): JsonResponse
    {
        $provider = $this->currentProvider($request);

        $this->closeInactiveConversationsForProvider($provider->id);

        $conversations = Conversation::query()
            ->with([
                'customer',
                'experience.coverPhoto',
                'experience.photos',
                'booking',
            ])
            ->where('provider_id', $provider->id)
            ->latest('last_message_at')
            ->latest()
            ->get()
            ->map(fn (Conversation $conversation) => $this->formatConversation(
                conversation: $conversation,
                viewer: 'provider',
            ))
            ->values();

        return response()->json([
            'message' => 'Conversaciones obtenidas correctamente.',
            'data' => $conversations,
            'meta' => $this->chatMeta(),
        ]);
    }

    public function show(Request $request, Conversation $conversation): JsonResponse
    {
        $provider = $this->currentProvider($request);

        $this->authorizeProvider($provider->id, $conversation);
        $this->autoCloseIfNeeded($conversation);

        $conversation->load([
            'customer',
            'experience.coverPhoto',
            'experience.photos',
            'booking',
        ]);

        return response()->json([
            'message' => 'Conversación obtenida correctamente.',
            'data' => $this->formatConversation(
                conversation: $conversation,
                viewer: 'provider',
            ),
            'meta' => $this->chatMeta(),
        ]);
    }

    public function messages(Request $request, Conversation $conversation): JsonResponse
    {
        $provider = $this->currentProvider($request);

        $this->authorizeProvider($provider->id, $conversation);
        $this->autoCloseIfNeeded($conversation);

        $messages = $conversation->messages()
            ->with('sender')
            ->oldest()
            ->get()
            ->map(fn (ConversationMessage $message) => $this->formatMessage($message))
            ->values();

        return response()->json([
            'message' => 'Mensajes obtenidos correctamente.',
            'data' => $messages,
            'conversation' => $this->formatConversation(
                conversation: $conversation->fresh([
                    'customer',
                    'experience.coverPhoto',
                    'experience.photos',
                    'booking',
                ]),
                viewer: 'provider',
            ),
            'meta' => $this->chatMeta(),
        ]);
    }

    public function sendMessage(Request $request, Conversation $conversation): JsonResponse
    {
        $provider = $this->currentProvider($request);

        $this->authorizeProvider($provider->id, $conversation);
        $this->autoCloseIfNeeded($conversation);

        if ($conversation->fresh()->isClosed()) {
            return response()->json([
                'message' => 'Este chat está cerrado. No puedes enviar mensajes en esta conversación.',
            ], 422);
        }

        $data = $request->validate([
            'message' => ['nullable', 'string', 'max:2000'],
            'image' => [
                'nullable',
                'image',
                'mimes:' . implode(',', config('chat.allowed_image_mimes')),
                'max:' . config('chat.max_image_size_kb'),
            ],
        ]);

        if (
            blank($data['message'] ?? null) &&
            ! $request->hasFile('image')
        ) {
            return response()->json([
                'message' => 'Debes enviar un mensaje o una imagen.',
            ], 422);
        }

        $user = $request->user();

        $message = DB::transaction(function () use ($request, $conversation, $data, $user) {
            $attachmentData = $this->storeAttachmentIfPresent($request, $conversation);

            $message = ConversationMessage::query()->create([
                'conversation_id' => $conversation->id,
                'sender_user_id' => $user->id,
                'sender_type' => 'provider',
                'message' => filled($data['message'] ?? null)
                    ? trim($data['message'])
                    : null,
                ...$attachmentData,
            ]);

            $lastMessage = $message->message
                ?: ($message->attachment_path ? 'Imagen enviada' : null);

            $conversation->forceFill([
                'status' => 'open',
                'closed_reason' => null,
                'closed_at' => null,
                'last_message' => $lastMessage,
                'last_message_at' => now(),
            ])->save();

            $conversation->increment('customer_unread_count');

            return $message;
        });

        $conversation->load(['customer', 'experience']);

        if ($conversation->customer) {
            $this->pushNotificationService->sendToUser(
                user: $conversation->customer,
                title: 'El afiliado respondió tu mensaje',
                body: $conversation->last_message ?? 'Tienes un nuevo mensaje.',
                data: [
                    'type' => 'chat_message',
                    'conversation_id' => (string) $conversation->id,
                    'role' => 'customer',
                ],
            );
        }

        return response()->json([
            'message' => 'Mensaje enviado correctamente.',
            'data' => $this->formatMessage($message->load('sender')),
        ], 201);
    }

    public function markAsRead(Request $request, Conversation $conversation): JsonResponse
    {
        $provider = $this->currentProvider($request);

        $this->authorizeProvider($provider->id, $conversation);

        DB::transaction(function () use ($conversation) {
            $conversation->messages()
                ->where('sender_type', 'customer')
                ->whereNull('read_at')
                ->update([
                    'read_at' => now(),
                ]);

            $conversation->update([
                'provider_unread_count' => 0,
            ]);
        });

        return response()->json([
            'message' => 'Conversación marcada como leída.',
        ]);
    }

    public function close(Request $request, Conversation $conversation): JsonResponse
    {
        $provider = $this->currentProvider($request);

        $this->authorizeProvider($provider->id, $conversation);
        $this->autoCloseIfNeeded($conversation);

        $conversation = $conversation->fresh();

        if (! $conversation->isClosed()) {
            $conversation->update([
                'status' => 'closed',
                'closed_reason' => 'provider_closed',
                'closed_at' => now(),
            ]);
        }

        $conversation->load([
            'customer',
            'experience.coverPhoto',
            'experience.photos',
            'booking',
        ]);

        return response()->json([
            'message' => 'Chat cerrado correctamente.',
            'data' => $this->formatConversation(
                conversation: $conversation,
                viewer: 'provider',
            ),
            'meta' => $this->chatMeta(),
        ]);
    }

    public function unreadCount(Request $request): JsonResponse
    {
        $provider = $this->currentProvider($request);

        $this->closeInactiveConversationsForProvider($provider->id);

        $count = Conversation::query()
            ->where('provider_id', $provider->id)
            ->sum('provider_unread_count');

        return response()->json([
            'message' => 'Contador obtenido correctamente.',
            'data' => [
                'unread_count' => (int) $count,
            ],
        ]);
    }

    private function currentProvider(Request $request)
    {
        $provider = $request->user()
            ->provider()
            ->first();

        if (! $provider) {
            abort(403, 'Este usuario no tiene perfil de proveedor.');
        }

        return $provider;
    }

    private function authorizeProvider(int $providerId, Conversation $conversation): void
    {
        if ((int) $conversation->provider_id !== (int) $providerId) {
            abort(403, 'No tienes permiso para acceder a esta conversación.');
        }
    }

    private function autoCloseIfNeeded(Conversation $conversation): void
    {
        if ($conversation->shouldAutoClose()) {
            $conversation->closeByInactivity();
            $conversation->refresh();
        }
    }

    private function closeInactiveConversationsForProvider(int $providerId): void
    {
        Conversation::query()
            ->where('provider_id', $providerId)
            ->where('status', 'open')
            ->where(function ($query) {
                $limit = now()->subHours(config('chat.auto_close_hours', 72));

                $query->where('last_message_at', '<=', $limit)
                    ->orWhere(function ($fallback) use ($limit) {
                        $fallback->whereNull('last_message_at')
                            ->where('created_at', '<=', $limit);
                    });
            })
            ->update([
                'status' => 'closed',
                'closed_reason' => 'inactive',
                'closed_at' => now(),
            ]);
    }

    private function storeAttachmentIfPresent(Request $request, Conversation $conversation): array
    {
        if (! $request->hasFile('image')) {
            return [
                'attachment_path' => null,
                'attachment_type' => null,
                'attachment_original_name' => null,
                'attachment_mime_type' => null,
                'attachment_size_bytes' => null,
            ];
        }

        $file = $request->file('image');

        $path = $file->store(
            "chat/conversations/{$conversation->id}",
            'public'
        );

        return [
            'attachment_path' => $path,
            'attachment_type' => 'image',
            'attachment_original_name' => $file->getClientOriginalName(),
            'attachment_mime_type' => $file->getMimeType(),
            'attachment_size_bytes' => $file->getSize(),
        ];
    }

    private function formatConversation(Conversation $conversation, string $viewer): array
    {
        $experience = $conversation->experience;
        $provider = $conversation->provider;
        $customer = $conversation->customer;

        return [
            'id' => $conversation->id,
            'status' => $conversation->status,
            'closed_reason' => $conversation->closed_reason,
            'closed_at' => optional($conversation->closed_at)->toIso8601String(),
            'customer_user_id' => $conversation->customer_user_id,
            'provider_id' => $conversation->provider_id,
            'provider_experience_id' => $conversation->provider_experience_id,
            'provider_booking_id' => $conversation->provider_booking_id,
            'last_message' => $conversation->last_message,
            'last_message_at' => optional($conversation->last_message_at)->toIso8601String(),
            'unread_count' => $viewer === 'customer'
                ? (int) $conversation->customer_unread_count
                : (int) $conversation->provider_unread_count,
            'auto_closes_after_hours' => config('chat.auto_close_hours', 72),
            'inactivity_notice' => config('chat.inactivity_notice'),
            'experience' => [
                'id' => $experience?->id,
                'title' => $experience?->title,
                'cover_photo_url' => $this->resolveExperienceCoverPhotoUrl($experience),
            ],
            'provider' => [
                'id' => $provider?->id,
                'business_name' => $provider?->business_name,
                'user_name' => $provider?->user?->name,
            ],
            'customer' => [
                'id' => $customer?->id,
                'name' => $customer?->name,
                'email' => $customer?->email,
            ],
            'booking' => $conversation->booking ? [
                'id' => $conversation->booking->id,
                'booking_code' => $conversation->booking->booking_code,
                'status' => $conversation->booking->status,
            ] : null,
        ];
    }

    private function formatMessage(ConversationMessage $message): array
    {
        return [
            'id' => $message->id,
            'conversation_id' => $message->conversation_id,
            'sender_user_id' => $message->sender_user_id,
            'sender_type' => $message->sender_type,
            'sender_name' => $message->sender?->name,
            'message' => $message->message,
            'attachment_type' => $message->attachment_type,
            'attachment_url' => $message->attachment_url,
            'attachment_original_name' => $message->attachment_original_name,
            'attachment_mime_type' => $message->attachment_mime_type,
            'attachment_size_bytes' => $message->attachment_size_bytes,
            'read_at' => optional($message->read_at)->toIso8601String(),
            'created_at' => optional($message->created_at)->toIso8601String(),
        ];
    }

    private function chatMeta(): array
    {
        return [
            'auto_closes_after_hours' => config('chat.auto_close_hours', 72),
            'inactivity_notice' => config('chat.inactivity_notice'),
            'attachments' => [
                'images_enabled' => true,
                'max_image_size_kb' => config('chat.max_image_size_kb'),
                'allowed_image_mimes' => config('chat.allowed_image_mimes'),
            ],
            'push_ready' => true,
            'push_enabled' => false,
        ];
    }

    private function resolveExperienceCoverPhotoUrl(?ProviderExperience $experience): ?string
    {
        if (! $experience) {
            return null;
        }

        $coverPhoto = $experience->coverPhoto;

        $firstPhoto = $experience->relationLoaded('photos')
            ? $experience->photos->sortBy('sort_order')->first()
            : $experience->photos()->orderBy('sort_order')->first();

        $photo = $coverPhoto ?? $firstPhoto;

        if (! $photo) {
            return null;
        }

        return url('/api/public-files/' . ltrim($photo->path, '/'));
    }
}