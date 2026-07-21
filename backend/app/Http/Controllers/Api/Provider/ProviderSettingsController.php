<?php

namespace App\Http\Controllers\Api\Provider;

use App\Http\Controllers\Controller;
use App\Http\Requests\Provider\ProviderOptionalDocumentRequest;
use App\Http\Requests\Provider\ProviderSettingsUpdateRequest;
use App\Models\Provider;
use App\Models\ProviderDocument;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\URL;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpFoundation\StreamedResponse;

class ProviderSettingsController extends Controller
{
    private const DOCUMENT_TYPES = [
        'identity_card' => [
            'label' => 'Cédula de identidad',
            'required' => true,
            'uploadable' => false,
        ],
        'rnc_certificate' => [
            'label' => 'Certificado RNC',
            'required' => true,
            'uploadable' => false,
        ],
        'business_license' => [
            'label' => 'Licencia comercial',
            'required' => false,
            'uploadable' => true,
        ],
        'insurance_policy' => [
            'label' => 'Póliza de seguro para clientes',
            'required' => false,
            'uploadable' => true,
        ],
    ];

    public function show(Request $request): JsonResponse
    {
        return $this->settingsResponse(
            $this->currentProvider($request)
        );
    }

    public function update(
        ProviderSettingsUpdateRequest $request
    ): JsonResponse {
        $provider = $this->currentProvider($request);
        $validated = $request->validated();

        DB::transaction(function () use ($request, $provider, $validated) {
            $request->user()->update([
                'phone' => $validated['phone'],
            ]);

            $provider->update([
                'city' => $validated['city'],
                'province' => $validated['province'],
            ]);
        });

        return $this->settingsResponse(
            $provider->fresh(),
            'Datos de contacto actualizados correctamente.'
        );
    }

    public function uploadOptionalDocuments(
        ProviderOptionalDocumentRequest $request
    ): JsonResponse {
        $provider = $this->currentProvider($request);

        $verificationRequest = $provider->verificationRequests()
            ->latest('id')
            ->first();

        if (! $verificationRequest) {
            throw ValidationException::withMessages([
                'documents' => [
                    'No se encontró una solicitud de verificación asociada.',
                ],
            ]);
        }

        $requestedDocuments = collect([
            'business_license' => 'business_license',
            'insurance_policy' => 'insurance_policy',
        ])->filter(
            fn (string $type, string $inputName): bool =>
                $request->hasFile($inputName)
        );

        foreach ($requestedDocuments as $inputName => $type) {
            $alreadyExists = $provider->documents()
                ->where('type', $type)
                ->exists();

            if ($alreadyExists) {
                $label = self::DOCUMENT_TYPES[$type]['label'];

                throw ValidationException::withMessages([
                    $inputName => [
                        "Ya existe un documento para {$label}.",
                    ],
                ]);
            }
        }

        $storedPaths = [];

        try {
            DB::transaction(function () use (
                $request,
                $provider,
                $verificationRequest,
                $requestedDocuments,
                &$storedPaths
            ) {
                $directory = "providers/{$provider->id}"
                    . "/verification_requests/{$verificationRequest->id}";

                foreach ($requestedDocuments as $inputName => $type) {
                    $file = $request->file($inputName);
                    $path = $file->store($directory, 'private');

                    $storedPaths[] = $path;

                    ProviderDocument::query()->create([
                        'provider_id' => $provider->id,
                        'provider_verification_request_id' =>
                            $verificationRequest->id,
                        'type' => $type,
                        'status' => 'pending',
                        'disk' => 'private',
                        'path' => $path,
                        'original_name' => $file->getClientOriginalName(),
                        'mime_type' => $file->getClientMimeType(),
                        'size_bytes' => $file->getSize(),
                    ]);
                }
            });
        } catch (\Throwable $exception) {
            foreach ($storedPaths as $storedPath) {
                Storage::disk('private')->delete($storedPath);
            }

            throw $exception;
        }

        return $this->settingsResponse(
            $provider,
            'Documentos opcionales enviados correctamente.'
        );
    }

    public function documentFile(
        Request $request,
        ProviderDocument $document
    ): StreamedResponse {
        $disk = $document->disk ?: 'private';

        if (! Storage::disk($disk)->exists($document->path)) {
            abort(404, 'El archivo solicitado no está disponible.');
        }

        $disposition = $request->query('disposition') === 'attachment'
            ? 'attachment'
            : 'inline';

        $fileName = str_replace(
            ["\r", "\n", '"'],
            '',
            $document->original_name
        );

        if (blank($fileName)) {
            $fileName = basename($document->path);
        }

        return Storage::disk($disk)->response(
            $document->path,
            $fileName,
            [
                'Cache-Control' => 'private, no-store, max-age=0',
                'X-Content-Type-Options' => 'nosniff',
            ],
            $disposition
        );
    }

    private function currentProvider(Request $request): Provider
    {
        $provider = Provider::query()
            ->where('user_id', $request->user()->id)
            ->first();

        if (! $provider) {
            abort(403, 'Este usuario no tiene un perfil de afiliado.');
        }

        return $provider;
    }

    private function settingsResponse(
        Provider $provider,
        ?string $message = null
    ): JsonResponse {
        $user = $provider->user()->firstOrFail();

        $latestDocuments = $provider->documents()
            ->latest('id')
            ->get()
            ->unique('type')
            ->keyBy('type');

        $documents = collect(self::DOCUMENT_TYPES)
            ->map(function (array $definition, string $type) use (
                $latestDocuments
            ) {
                $document = $latestDocuments->get($type);
                $isUploaded = $document !== null;

                return [
                    'id' => $document?->id,
                    'type' => $type,
                    'label' => $definition['label'],
                    'is_required' => $definition['required'],
                    'is_uploaded' => $isUploaded,
                    'can_upload' =>
                        $definition['uploadable'] && ! $isUploaded,
                    'status' => $document?->status,
                    'original_name' => $document?->original_name,
                    'mime_type' => $document?->mime_type,
                    'size_bytes' => (int) ($document?->size_bytes ?? 0),
                    'uploaded_at' =>
                        $document?->created_at?->toISOString(),
                    'view_url' => $document
                        ? $this->documentUrl($document, 'inline')
                        : null,
                    'download_url' => $document
                        ? $this->documentUrl($document, 'attachment')
                        : null,
                ];
            })
            ->values();

        return response()->json([
            'message' => $message,
            'data' => [
                'phone' => $user->phone ?? '',
                'city' => $provider->city ?? '',
                'province' => $provider->province ?? '',
                'documents' => $documents,
            ],
        ]);
    }

    private function documentUrl(
        ProviderDocument $document,
        string $disposition
    ): string {
        return URL::temporarySignedRoute(
            'api.provider.documents.file',
            now()->addMinutes(30),
            [
                'document' => $document->id,
                'disposition' => $disposition,
            ]
        );
    }
}
