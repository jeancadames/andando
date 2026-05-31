<?php

namespace App\Http\Controllers\Api\Provider;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class ProviderExperienceReviewController extends Controller
{
    public function summary(Request $request, int $experienceId)
    {
        $providerId = $this->currentProviderId($request);
        $experience = $this->findExperienceOrFail($providerId, $experienceId);

        $summary = $this->buildSummary($providerId, $experienceId, $experience);

        return response()->json([
            'data' => [
                'experience_id' => $experienceId,
                'experience_title' => $summary['experience_title'],
                'average_rating' => $summary['average_rating'],
                'total_reviews' => $summary['total_reviews'],
                'rating_distribution' => $summary['rating_distribution'],
                'reviews' => [],
            ],
        ]);
    }

    public function index(Request $request, int $experienceId)
    {
        $providerId = $this->currentProviderId($request);
        $experience = $this->findExperienceOrFail($providerId, $experienceId);

        $summary = $this->buildSummary($providerId, $experienceId, $experience);

        $reviews = $this->baseReviewsQuery($providerId, $experienceId)
            ->select([
                'provider_reviews.id',
                'provider_reviews.rating',
                'provider_reviews.comment',
                'provider_reviews.provider_response',
                'provider_reviews.provider_response_at',
                'provider_reviews.created_at',
                DB::raw($this->clientNameExpression() . ' as client_name'),
            ])
            ->orderByDesc('provider_reviews.created_at')
            ->get()
            ->map(fn ($review) => $this->formatReview($review))
            ->values();

        return response()->json([
            'data' => [
                'experience_id' => $experienceId,
                'experience_title' => $summary['experience_title'],
                'average_rating' => $summary['average_rating'],
                'total_reviews' => $summary['total_reviews'],
                'rating_distribution' => $summary['rating_distribution'],
                'reviews' => $reviews,
            ],
        ]);
    }

    public function reply(Request $request, int $experienceId, int $reviewId)
    {
        $data = $request->validate([
            'response' => ['required', 'string', 'min:2', 'max:2000'],
        ]);

        $providerId = $this->currentProviderId($request);

        $this->findExperienceOrFail($providerId, $experienceId);

        $review = $this->baseReviewsQuery($providerId, $experienceId)
            ->where('provider_reviews.id', $reviewId)
            ->select('provider_reviews.id')
            ->first();

        if (!$review) {
            abort(404, 'Reseña no encontrada.');
        }

        DB::table('provider_reviews')
            ->where('id', $reviewId)
            ->where('provider_id', $providerId)
            ->update([
                'provider_response' => trim($data['response']),
                'provider_response_at' => now(),
                'updated_at' => now(),
            ]);

        return response()->json([
            'message' => 'Respuesta guardada correctamente.',
        ]);
    }

    private function currentProviderId(Request $request): int
    {
        $user = $request->user();

        if (!$user) {
            abort(401, 'No autenticado.');
        }

        $providerId = null;

        if (Schema::hasTable('providers')) {
            $providerId = DB::table('providers')
                ->where('user_id', $user->id)
                ->value('id');
        }

        if (!$providerId && isset($user->provider_id)) {
            $providerId = $user->provider_id;
        }

        if (!$providerId) {
            abort(403, 'No tienes un perfil de afiliado asociado.');
        }

        return (int) $providerId;
    }

    private function experienceTable(): string
    {
        if (Schema::hasTable('provider_experiences')) {
            return 'provider_experiences';
        }

        if (Schema::hasTable('experiences')) {
            return 'experiences';
        }

        abort(500, 'No existe tabla de experiencias.');
    }

    private function findExperienceOrFail(int $providerId, int $experienceId): object
    {
        $table = $this->experienceTable();

        $query = DB::table($table)
            ->where('id', $experienceId);

        if (Schema::hasColumn($table, 'provider_id')) {
            $query->where('provider_id', $providerId);
        }

        $experience = $query->first();

        if (!$experience) {
            abort(404, 'Experiencia no encontrada.');
        }

        return $experience;
    }

    private function baseReviewsQuery(int $providerId, int $experienceId)
    {
        $query = DB::table('provider_reviews')
            ->leftJoin('users', 'users.id', '=', 'provider_reviews.user_id')
            ->where('provider_reviews.provider_id', $providerId)
            ->where('provider_reviews.is_visible', 1);

        /*
         * Tu tabla SÍ tiene provider_reviews.provider_experience_id.
         * Este es el filtro correcto y directo.
         */
        if (Schema::hasColumn('provider_reviews', 'provider_experience_id')) {
            return $query->where(
                'provider_reviews.provider_experience_id',
                $experienceId
            );
        }

        /*
         * Fallback por si en otro ambiente viejo la reseña no tiene
         * provider_experience_id y hay que buscar por la reserva.
         */
        if (
            Schema::hasTable('provider_bookings') &&
            Schema::hasColumn('provider_reviews', 'provider_booking_id')
        ) {
            $experienceColumn = null;

            if (Schema::hasColumn('provider_bookings', 'provider_experience_id')) {
                $experienceColumn = 'provider_experience_id';
            } elseif (Schema::hasColumn('provider_bookings', 'experience_id')) {
                $experienceColumn = 'experience_id';
            }

            if ($experienceColumn) {
                return $query
                    ->join(
                        'provider_bookings',
                        'provider_bookings.id',
                        '=',
                        'provider_reviews.provider_booking_id'
                    )
                    ->where("provider_bookings.$experienceColumn", $experienceId);
            }
        }

        return $query->whereRaw('1 = 0');
    }

    private function buildSummary(
        int $providerId,
        int $experienceId,
        object $experience
    ): array {
        $base = $this->baseReviewsQuery($providerId, $experienceId);

        $totalReviews = (clone $base)->count('provider_reviews.id');

        $averageRating = (float) (
            (clone $base)->avg('provider_reviews.rating') ?? 0
        );

        $grouped = (clone $base)
            ->select('provider_reviews.rating', DB::raw('COUNT(*) as total'))
            ->groupBy('provider_reviews.rating')
            ->pluck('total', 'provider_reviews.rating');

        $distribution = [];

        for ($stars = 5; $stars >= 1; $stars--) {
            $count = (int) ($grouped[$stars] ?? 0);

            $distribution[] = [
                'stars' => $stars,
                'count' => $count,
                'percentage' => $totalReviews > 0
                    ? (int) round(($count / $totalReviews) * 100)
                    : 0,
            ];
        }

        return [
            'experience_title' => $experience->title
                ?? $experience->name
                ?? 'Experiencia',
            'average_rating' => round($averageRating, 1),
            'total_reviews' => $totalReviews,
            'rating_distribution' => $distribution,
        ];
    }

    private function formatReview(object $review): array
    {
        $clientName = trim($review->client_name ?: 'Cliente');

        return [
            'id' => (int) $review->id,
            'client_name' => $clientName,
            'client_initials' => $this->initials($clientName),
            'rating' => (int) $review->rating,
            'comment' => $review->comment,
            'date' => $this->dateToIso($review->created_at),
            'response' => $review->provider_response
                ? [
                    'text' => $review->provider_response,
                    'date' => $this->dateToIso($review->provider_response_at),
                ]
                : null,
        ];
    }

    private function clientNameExpression(): string
    {
        $parts = [];

        if (Schema::hasColumn('users', 'name')) {
            $parts[] = 'users.name';
        }

        if (Schema::hasColumn('users', 'full_name')) {
            $parts[] = 'users.full_name';
        }

        if (
            Schema::hasColumn('users', 'first_name') &&
            Schema::hasColumn('users', 'last_name')
        ) {
            $parts[] = "NULLIF(TRIM(CONCAT(COALESCE(users.first_name, ''), ' ', COALESCE(users.last_name, ''))), '')";
        }

        if (Schema::hasColumn('users', 'email')) {
            $parts[] = 'users.email';
        }

        if (empty($parts)) {
            return "'Cliente'";
        }

        return 'COALESCE(' . implode(', ', $parts) . ", 'Cliente')";
    }

    private function initials(string $name): string
    {
        $parts = preg_split('/\s+/', trim($name));

        if (!$parts || count($parts) === 0) {
            return 'CL';
        }

        $first = mb_substr($parts[0] ?? 'C', 0, 1);
        $second = mb_substr($parts[1] ?? $parts[0] ?? 'L', 0, 1);

        return mb_strtoupper($first . $second);
    }

    public function deleteReply(Request $request, int $experienceId, int $reviewId)
    {
        $providerId = $this->currentProviderId($request);

        $this->findExperienceOrFail($providerId, $experienceId);

        $review = $this->baseReviewsQuery($providerId, $experienceId)
            ->where('provider_reviews.id', $reviewId)
            ->select('provider_reviews.id')
            ->first();

        if (!$review) {
            abort(404, 'Reseña no encontrada.');
        }

        DB::table('provider_reviews')
            ->where('id', $reviewId)
            ->where('provider_id', $providerId)
            ->update([
                'provider_response' => null,
                'provider_response_at' => null,
                'updated_at' => now(),
            ]);

        return response()->json([
            'message' => 'Respuesta eliminada correctamente.',
        ]);
    }

    private function dateToIso($value): ?string
    {
        if (!$value) {
            return null;
        }

        return Carbon::parse($value)->toISOString();
    }
}