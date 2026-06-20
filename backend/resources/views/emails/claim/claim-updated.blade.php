@extends('emails.layouts.app')

@section('content')

@php
    $isResolved = $claim->status === 'resolved';
@endphp

<h1 style="font-size:36px; color:#003b88; margin-bottom:16px;">
    {{ $isResolved ? 'Tu reclamo fue resuelto' : 'Tu reclamo fue actualizado' }}
</h1>

<p style="font-size:16px; line-height:1.7;">
    Hola <strong>{{ $user->name }}</strong>,
</p>

<p style="font-size:16px; line-height:1.7;">
    @if ($isResolved)
        Tu reclamo ha sido marcado como resuelto por el equipo de AndanDO.
    @else
        Tu reclamo ha sido revisado y actualizado por el equipo de AndanDO.
    @endif
</p>

<table width="100%" cellpadding="0" cellspacing="0" style="border:1px solid #e5e7eb; border-radius:16px; margin:30px 0;">
    <tr>
        <td style="padding:24px;">
            <h3 style="color:#003b88; margin-top:0;">Detalles del reclamo</h3>

            <p><strong>Experiencia:</strong> {{ $booking?->experience?->title ?? 'Experiencia AndanDO' }}</p>
            <p><strong>Código de reserva:</strong> #{{ $booking?->booking_code }}</p>
            <p><strong>Motivo:</strong> {{ $claim->reason }}</p>
            <p><strong>Estado actual:</strong> {{ $isResolved ? 'Resuelto' : 'Rechazado' }}</p>
            <p><strong>Fecha de actualización:</strong> {{ $claim->resolved_at?->format('d/m/Y h:i A') }}</p>
        </td>
    </tr>
</table>

<table width="100%" cellpadding="0" cellspacing="0" style="background:#f1f6ff; border-radius:16px; margin-bottom:30px;">
    <tr>
        <td style="padding:24px;">
            <h3 style="color:#003b88; margin-top:0;">Información importante</h3>

            @if ($isResolved)
                <p>✓ El caso fue cerrado como resuelto.</p>
                <p>✓ Puedes consultar los detalles desde la app.</p>
                <p>✓ Gracias por ayudarnos a mantener la calidad de AndanDO.</p>
            @else
                <p>✓ El caso fue cerrado luego de la revisión.</p>
                <p>✓ Puedes consultar los detalles desde la app.</p>
                <p>✓ Si necesitas orientación adicional, puedes contactar soporte.</p>
            @endif
        </td>
    </tr>
</table>

<div style="text-align:center;">
    <a href="{{ $actionUrl ?? '#' }}"
       style="background:#ef233c; color:white; padding:14px 34px; border-radius:8px; text-decoration:none; font-weight:bold; display:inline-block;">
        Ver reclamo
    </a>
</div>

@endsection