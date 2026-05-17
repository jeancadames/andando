<?php

namespace App\Http\Controllers\Api\Client;

use App\Http\Controllers\Controller;
use App\Models\CustomerFavoriteExperience;
use App\Models\ProviderExperience;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ClientFavoriteExperienceController extends Controller
{
    public function store(Request $request, int $experience): JsonResponse
    {
        ProviderExperience::query()
            ->where('status', 'published')
            ->where('is_active', true)
            ->findOrFail($experience);

        CustomerFavoriteExperience::firstOrCreate([
            'user_id' => $request->user()->id,
            'provider_experience_id' => $experience,
        ]);

        return response()->json([
            'message' => 'Experiencia agregada a favoritos.',
            'data' => [
                'experience_id' => $experience,
                'is_favorite' => true,
            ],
        ]);
    }

    public function destroy(Request $request, int $experience): JsonResponse
    {
        CustomerFavoriteExperience::query()
            ->where('user_id', $request->user()->id)
            ->where('provider_experience_id', $experience)
            ->delete();

        return response()->json([
            'message' => 'Experiencia eliminada de favoritos.',
            'data' => [
                'experience_id' => $experience,
                'is_favorite' => false,
            ],
        ]);
    }
}