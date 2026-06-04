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
     *
     * Visitantes pueden ver comentarios.
     * Usuarios autenticados podrán identificar cuáles comentarios son suyos.
     */
    public function index(Request $request, ProviderReview $review): JsonResponse
    {
        $comments = $review->visibleComments()
            ->with('user')
            ->get()
            ->map(function (ProviderReviewComment $comment) use ($request) {
                return $this->commentPayload($comment, $request);
            })
            ->values();

        return response()->json([
            'message' => 'Comentarios obtenidos correctamente.',
            'data' => $comments,
        ]);
    }

    /**
     * Crea un comentario sobre una reseña.
     *
     * Reglas:
     * - El usuario debe estar autenticado.
     * - La reseña debe estar visible.
     * - El comentario no puede superar 300 caracteres.
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
     *
     * Solo el usuario que creó el comentario puede editarlo.
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
     * Elimina un comentario propio.
     *
     * Se usa borrado lógico de visibilidad para no romper conteos futuros.
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
     * Formato estándar que consume Flutter.
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
            'created_at' => $comment->created_at?->toIso8601String(),
            'updated_at' => $comment->updated_at?->toIso8601String(),
            'is_owner' => $user
                ? (int) $comment->user_id === (int) $user->id
                : false,
        ];
    }
}