<?php

namespace App\Http\Controllers\Api\Client;

use App\Http\Controllers\Controller;
use App\Models\ProviderReview;
use App\Models\ProviderReviewComment;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ClientReviewCommentController extends Controller
{
    /**
     * Lista los comentarios visibles de una reseña.
     */
    public function index(Request $request, ProviderReview $review): JsonResponse
    {
        $comments = $review->visibleComments()
            ->with('user')
            ->get()
            ->map(fn (ProviderReviewComment $comment) => $this->commentPayload(
                $comment,
                $request,
            ))
            ->values();

        return response()->json([
            'message' => 'Comentarios obtenidos correctamente.',
            'data' => $comments,
        ]);
    }

    /**
     * Crea un comentario sobre una reseña visible.
     */
    public function store(Request $request, ProviderReview $review): JsonResponse
    {
        if (! $review->is_visible) {
            return response()->json([
                'message' => 'No puedes comentar una reseña no disponible.',
            ], 422);
        }

        $data = $request->validate([
            'comment' => ['required', 'string', 'max:300'],
        ]);

        $comment = ProviderReviewComment::create([
            'provider_review_id' => $review->id,
            'user_id' => $request->user()->id,
            'comment' => trim($data['comment']),
            'is_visible' => true,
        ]);

        $comment->load('user');

        return response()->json([
            'message' => 'Comentario publicado correctamente.',
            'data' => $this->commentPayload($comment, $request),
        ], 201);
    }

    /**
     * Actualiza un comentario propio.
     */
    public function update(
        Request $request,
        ProviderReviewComment $comment
    ): JsonResponse {
        if ((int) $comment->user_id !== (int) $request->user()->id) {
            return response()->json([
                'message' => 'No tienes permiso para editar este comentario.',
            ], 403);
        }

        $data = $request->validate([
            'comment' => ['required', 'string', 'max:300'],
        ]);

        $comment->update([
            'comment' => trim($data['comment']),
        ]);

        $comment->load('user');

        return response()->json([
            'message' => 'Comentario actualizado correctamente.',
            'data' => $this->commentPayload($comment, $request),
        ]);
    }

    /**
     * Oculta un comentario propio.
     */
    public function destroy(
        Request $request,
        ProviderReviewComment $comment
    ): JsonResponse {
        if ((int) $comment->user_id !== (int) $request->user()->id) {
            return response()->json([
                'message' => 'No tienes permiso para eliminar este comentario.',
            ], 403);
        }

        $comment->update([
            'is_visible' => false,
        ]);

        return response()->json([
            'message' => 'Comentario eliminado correctamente.',
        ]);
    }

    /**
     * Payload estándar para Flutter.
     */
    private function commentPayload(
        ProviderReviewComment $comment,
        Request $request
    ): array {
        $user = $request->user();

        return [
            'id' => $comment->id,
            'review_id' => $comment->provider_review_id,
            'comment' => $comment->comment,
            'user_name' => $comment->user?->name ?? 'Usuario',
            'user_photo_url' => $this->userPhotoUrl($comment->user),
            'created_at' => $comment->created_at?->toIso8601String(),
            'updated_at' => $comment->updated_at?->toIso8601String(),
            'is_edited' => $this->isEdited($comment->created_at, $comment->updated_at),
            'is_owner' => $user
                ? (int) $comment->user_id === (int) $user->id
                : false,
        ];
    }

    /**
     * Resuelve la foto pública del usuario.
     */
    private function userPhotoUrl($user): ?string
    {
        if (! $user) {
            return null;
        }

        $path = $user->photo_path
            ?? $user->avatar_path
            ?? $user->profile_photo_path
            ?? null;

        if (! $path) {
            return null;
        }

        if (str_starts_with($path, 'http://') || str_starts_with($path, 'https://')) {
            return $path;
        }

        return url('/api/storage/' . ltrim($path, '/'));
    }

    /**
     * Indica si fue editado después de crearse.
     */
    private function isEdited($createdAt, $updatedAt): bool
    {
        if (! $createdAt || ! $updatedAt) {
            return false;
        }

        return $updatedAt->gt($createdAt->copy()->addSeconds(2));
    }
}