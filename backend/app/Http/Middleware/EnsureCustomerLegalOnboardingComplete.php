<?php

namespace App\Http\Middleware;

use App\Models\User;
use App\Services\Legal\CustomerLegalOnboardingService;
use Closure;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureCustomerLegalOnboardingComplete
{
    public function __construct(
        private readonly CustomerLegalOnboardingService $onboardingService
    ) {
    }

    public function handle(
        Request $request,
        Closure $next
    ): Response {
        /** @var User|null $user */
        $user = $request->user();

        if ($user === null) {
            return $next($request);
        }

        if ($user->type !== 'customer') {
            return $next($request);
        }

        /*
         * Esta protección se limita inicialmente a cuentas sociales.
         *
         * Las cuentas tradicionales nuevas ya completan los requisitos
         * legales durante su registro.
         */
        if (
            $user->firebase_uid === null
            || trim((string) $user->firebase_uid) === ''
        ) {
            return $next($request);
        }

        if ($this->onboardingService->isComplete($user)) {
            return $next($request);
        }

        return new JsonResponse([
            'message' => 'Debes completar tu información legal antes de continuar.',
            'code' => 'legal_onboarding_required',
            'requires_legal_onboarding' => true,
            'onboarding_path' => '/auth/social/legal-onboarding',
        ], 409);
    }
}