<?php

namespace Database\Seeders;

use App\Models\LegalDocument;
use Carbon\CarbonImmutable;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use RuntimeException;

class LegalDocumentSeeder extends Seeder
{
    public function run(): void
    {
        $effectiveAt = CarbonImmutable::create(
            2026,
            7,
            18,
            0,
            0,
            0,
            config('app.timezone')
        );

        $documents = [
            [
                'type' => 'terms_user',
                'audience' => 'customer',
                'version' => '1.0',
                'title' => 'Términos y Condiciones de Usuarios',
                'summary' => 'Contrato marco para el uso de AndanDO por clientes adultos.',
                'path' => database_path('legal/terms_user_v1.0.md'),
                'requires_acceptance' => true,
                'change_level' => LegalDocument::CHANGE_LEVEL_MATERIAL,
            ],
            [
                'type' => 'privacy',
                'audience' => 'customer',
                'version' => '1.0',
                'title' => 'Política de Privacidad',
                'summary' => 'Información sobre el tratamiento de datos personales en AndanDO.',
                'path' => database_path('legal/privacy_v1.0.md'),
                'requires_acceptance' => false,
                'change_level' => LegalDocument::CHANGE_LEVEL_MATERIAL,
            ],
            [
                'type' => 'cookies',
                'audience' => 'customer',
                'version' => '1.0',
                'title' => 'Política de Cookies y Tecnologías Similares',
                'summary' => 'Uso de cookies, almacenamiento local, sesiones, permisos y notificaciones.',
                'path' => database_path('legal/cookies_v1.0.md'),
                'requires_acceptance' => false,
                'change_level' => LegalDocument::CHANGE_LEVEL_MATERIAL,
            ],
        ];

        DB::transaction(function () use ($documents, $effectiveAt): void {
            foreach ($documents as $definition) {
                if (! is_file($definition['path'])) {
                    throw new RuntimeException(
                        "No existe el archivo legal: {$definition['path']}"
                    );
                }

                $content = file_get_contents($definition['path']);

                if ($content === false || trim($content) === '') {
                    throw new RuntimeException(
                        "El archivo legal está vacío o no pudo leerse: {$definition['path']}"
                    );
                }

                LegalDocument::query()
                    ->where('type', $definition['type'])
                    ->where('audience', $definition['audience'])
                    ->where('version', '!=', $definition['version'])
                    ->update([
                        'is_active' => false,
                    ]);

                LegalDocument::query()->updateOrCreate(
                    [
                        'type' => $definition['type'],
                        'audience' => $definition['audience'],
                        'version' => $definition['version'],
                    ],
                    [
                        'title' => $definition['title'],
                        'content' => $content,
                        'summary' => $definition['summary'],
                        'content_format' => 'markdown',
                        'effective_at' => $effectiveAt,
                        'published_at' => $effectiveAt,
                        'requires_acceptance' => $definition['requires_acceptance'],
                        'change_level' => $definition['change_level'],
                        'is_active' => true,
                        'checksum' => LegalDocument::calculateChecksum($content),
                        'supersedes_id' => null,
                    ]
                );
            }
        });
    }
}