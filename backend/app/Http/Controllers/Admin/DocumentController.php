<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\ProviderDocument;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\HttpFoundation\StreamedResponse;

/**
 * Sirve los documentos del afiliado.
 *
 * Los archivos viven en un disco privado (provider_documents.disk),
 * así que NO son accesibles públicamente. Esta ruta está detrás del
 * middleware admin y entrega el archivo en línea (inline) para poder
 * verlo en el navegador (PDF o imagen).
 */
class DocumentController extends Controller
{
    public function show(ProviderDocument $document): StreamedResponse
    {
        $disk = Storage::disk($document->disk ?: 'local');

        abort_unless($disk->exists($document->path), 404, 'Documento no encontrado.');

        return $disk->response(
            $document->path,
            $document->original_name,
            [
                'Content-Type' => $document->mime_type ?: 'application/octet-stream',
                'Content-Disposition' => 'inline; filename="' . addslashes($document->original_name) . '"',
            ]
        );
    }
}
