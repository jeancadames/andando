@extends('emails.layouts.app')

@section('content')

<h1 style="font-size:36px; color:#003b88; margin-bottom:16px;">
    Hemos recibido tu reclamo 📋
</h1>

<p style="font-size:16px; line-height:1.7;">
    Hola <strong>{{ $user->name }}</strong>,
</p>

<p style="font-size:16px; line-height:1.7;">
    Tu reclamo fue registrado correctamente. Nuestro equipo revisará el caso y te mantendremos informado.
</p>

<table width="100%" cellpadding="0" cellspacing="0" style="border:1px solid #e5e7eb; border-radius:16px; margin:30px 0;">
    <tr>
        <td style="padding:24px;">
            <h3 style="color:#003b88; margin-top:0;">Detalles del reclamo</h3>

            <p><strong>Experiencia:</strong> {{ $booking?->experience?->title ?? 'Experiencia AndanDO' }}</p>
            <p><strong>Código de reserva:</strong> #{{ $booking?->booking_code }}</p>
            <p><strong>Motivo:</strong> {{ $claim->reason }}</p>
            <p><strong>Descripción:</strong> {{ $claim->description ?: 'Sin descripción adicional' }}</p>
            <p><strong>Estado:</strong> Pendiente de revisión</p>
        </td>
    </tr>
</table>

<table width="100%" cellpadding="0" cellspacing="0" style="background:#f1f6ff; border-radius:16px; margin-bottom:30px;">
    <tr>
        <td style="padding:24px;">
            <h3 style="color:#003b88; margin-top:0;">Qué sucede ahora</h3>

            <p>✓ Revisaremos la información enviada.</p>
            <p>✓ El afiliado podrá responder al reclamo.</p>
            <p>✓ Te notificaremos cuando haya una actualización.</p>
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