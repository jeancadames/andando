@extends('emails.layouts.app')

@section('content')

<h1 style="font-size:36px; color:#003b88; margin-bottom:16px;">
    Nueva fecha disponible 🌴
</h1>

<p style="font-size:16px; line-height:1.7;">
    Hola <strong>{{ $user->name }}</strong>,
</p>

<p style="font-size:16px; line-height:1.7;">
    Una experiencia que tienes en favoritos acaba de publicar una nueva fecha disponible.
</p>

<table width="100%" cellpadding="0" cellspacing="0"
       style="border:1px solid #e5e7eb; border-radius:16px; margin:30px 0;">
    <tr>
        <td style="padding:24px;">
            <h3 style="color:#003b88; margin-top:0;">
                Detalles de la experiencia
            </h3>

            <p><strong>Experiencia:</strong> {{ $experience?->title ?? 'Experiencia AndanDO' }}</p>
            <p><strong>Provincia:</strong> {{ $experience?->province ?? 'No especificada' }}</p>
            <p><strong>Fecha:</strong> {{ $schedule->starts_at?->format('d/m/Y h:i A') }}</p>
            <p><strong>Cupos:</strong> {{ $schedule->capacity }}</p>
            <p><strong>Precio:</strong> RD$ {{ number_format((float) $schedule->price, 2) }}</p>
        </td>
    </tr>
</table>

<table width="100%" cellpadding="0" cellspacing="0"
       style="background:#f1f6ff; border-radius:16px; margin-bottom:30px;">
    <tr>
        <td style="padding:24px;">
            <h3 style="color:#003b88; margin-top:0;">
                Consejo
            </h3>

            <p>✓ Las fechas pueden llenarse rápidamente.</p>
            <p>✓ Revisa disponibilidad antes de reservar.</p>
            <p>✓ Si te interesa, reserva cuanto antes desde la app.</p>
        </td>
    </tr>
</table>

<div style="text-align:center;">
    <a href="{{ $actionUrl ?? '#' }}"
       style="background:#ef233c;
              color:white;
              padding:14px 34px;
              border-radius:8px;
              text-decoration:none;
              font-weight:bold;
              display:inline-block;">
        Ver experiencia
    </a>
</div>

@endsection