<?php

namespace App\Http\Controllers\Api\Client;

use App\Http\Controllers\Controller;
use App\Models\Conversation;
use App\Models\ConversationMessage;
use App\Models\ProviderExperience;
use App\Services\PushNotificationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ClientConversationController extends Controller
{
    public function __construct(
        private readonly PushNotificationService $pushNotificationService,
    ) {
    }

    public function index(Request $request): JsonResponse
    {
        $this->closeInactiveConversationsForCustomer($request->user()->id);

        $conversations = Conversation::query()
            ->with([
                'provider.user',
                'experience.coverPhoto',
                'experience.photos',
                'booking',
            ])
            ->where('customer_user_id', $request->user()->id)
            ->latest('last_message_at')
            ->latest()
            ->get()
            ->map(fn (Conversation $conversation) => $this->formatConversation(
                conversation: $conversation,
                viewer: 'customer',
            ))
            ->values();

        return response()->json([
            'message' => 'Conversaciones obtenidas correctamente.',
            'data' => $conversations,
            'meta' => $this->chatMeta(),
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'provider_experience_id' => [
                'required',
                'integer',
                'exists:provider_experiences,id',
            ],
        ]);

        $user = $request->user();

        if ($user->type !== 'customer') {
            return response()->json([
                'message' => 'Debes iniciar sesión como cliente para contactar al afiliado.',
            ], 403);
        }

        $experience = ProviderExperience::query()
            ->with(['provider.user', 'coverPhoto', 'photos'])
            ->where('id', $data['provider_experience_id'])
            ->where('status', 'published')
            ->where('is_active', true)
            ->whereNotNull('published_at')
            ->firstOrFail();

        $conversation = Conversation::query()
            ->where('customer_user_id', $user->id)
            ->where('provider_id', $experience->provider_id)
            ->where('provider_experience_id', $experience->id)
            ->first();

        if (! $conversation) {
            $conversation = Conversation::query()->create([
                'customer_user_id' => $user->id,
                'provider_id' => $experience->provider_id,
                'provider_experience_id' => $experience->id,
                'status' => 'open',
                'last_message_at' => now(),
            ]);
        }

        if ($conversation->shouldAutoClose()) {
            $conversation->closeByInactivity();
            $conversation->refresh();
        }

        /**
         * Si estaba cerrada por inactividad y el cliente vuelve a tocar
         * "Contactar afiliado", reabrimos el mismo historial.
         */
        if ($conversation->isClosed()) {
            $conversation->reopen();
            $conversation->refresh();
        }

        $conversation->load([
            'provider.user',
            'experience.coverPhoto',
            'experience.photos',
            'booking',
        ]);

        return response()->json([
            'message' => 'Conversación lista.',
            'data' => $this->formatConversation(
                conversation: $conversation,
                viewer: 'customer',
            ),
            'meta' => $this->chatMeta(),
        ]);
    }

    public function show(Request $request, Conversation $conversation): JsonResponse
    {
        $this->authorizeCustomer($request, $conversation);
        $this->autoCloseIfNeeded($conversation);

        $conversation->load([
            'provider.user',
            'experience.coverPhoto',
            'experience.photos',
            'booking',
        ]);

        return response()->json([
            'message' => 'Conversación obtenida correctamente.',
            'data' => $this->formatConversation(
                conversation: $conversation,
                viewer: 'customer',
            ),
            'meta' => $this->chatMeta(),
        ]);
    }

    public function messages(Request $request, Conversation $conversation): JsonResponse
    {
        $this->authorizeCustomer($request, $conversation);
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
                    'provider.user',
                    'experience.coverPhoto',
                    'experience.photos',
                    'booking',
                ]),
                viewer: 'customer',
            ),
            'meta' => $this->chatMeta(),
        ]);
    }

    public function sendMessage(Request $request, Conversation $conversation): JsonResponse
    {
        $this->authorizeCustomer($request, $conversation);
        $this->autoCloseIfNeeded($conversation);

        if ($conversation->fresh()->isClosed()) {
            return response()->json([
                'message' => 'Este chat fue cerrado por inactividad. Vuelve a contactar al afiliado para reabrirlo.',
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
                'sender_type' => 'customer',
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

            $conversation->increment('provider_unread_count');

            return $message;
        });

        $conversation->load(['provider.user', 'experience']);

        if ($conversation->provider?->user) {
            $this->pushNotificationService->sendToUser(
                user: $conversation->provider->user,
                title: 'Nuevo mensaje de cliente',
                body: $conversation->last_message ?? 'Tienes un nuevo mensaje.',
                data: [
                    'type' => 'chat_message',
                    'conversation_id' => (string) $conversation->id,
                    'role' => 'provider',
                ],
                category: PushNotificationService::CATEGORY_MESSAGE,
            );
        }

        return response()->json([
            'message' => 'Mensaje enviado correctamente.',
            'data' => $this->formatMessage($message->load('sender')),
        ], 201);
    }

    public function markAsRead(Request $request, Conversation $conversation): JsonResponse
    {
        $this->authorizeCustomer($request, $conversation);

        DB::transaction(function () use ($conversation) {
            $conversation->messages()
                ->where('sender_type', 'provider')
                ->whereNull('read_at')
                ->update([
                    'read_at' => now(),
                ]);

            $conversation->update([
                'customer_unread_count' => 0,
            ]);
        });

        return response()->json([
            'message' => 'Conversación marcada como leída.',
        ]);
    }

    public function unreadCount(Request $request): JsonResponse
    {
        $this->closeInactiveConversationsForCustomer($request->user()->id);

        $count = Conversation::query()
            ->where('customer_user_id', $request->user()->id)
            ->sum('customer_unread_count');

        return response()->json([
            'message' => 'Contador obtenido correctamente.',
            'data' => [
                'unread_count' => (int) $count,
            ],
        ]);
    }

    private function authorizeCustomer(Request $request, Conversation $conversation): void
    {
        if ((int) $conversation->customer_user_id !== (int) $request->user()->id) {
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

    private function closeInactiveConversationsForCustomer(int $userId): void
    {
        Conversation::query()
            ->where('customer_user_id', $userId)
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