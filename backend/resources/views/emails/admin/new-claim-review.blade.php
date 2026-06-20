@extends('emails.layouts.app')

@section('content')

<h1 style="font-size:36px; color:#003b88; margin-bottom:16px;">
    Nuevo reclamo pendiente 📋
</h1>

<p style="font-size:16px; line-height:1.7;">
    Se ha creado un nuevo reclamo que requiere revisión del equipo administrativo.
</p>

<table width="100%" cellpadding="0" cellspacing="0"
       style="border:1px solid #e5e7eb; border-radius:16px; margin:30px 0;">
    <tr>
        <td style="padding:24px;">
            <h3 style="color:#003b88; margin-top:0;">Detalles del reclamo</h3>

            <p><strong>Cliente:</strong> {{ $customer?->name ?? 'No disponible' }}</p>
            <p><strong>Email cliente:</strong> {{ $customer?->email ?? 'No disponible' }}</p>
            <p><strong>Afiliado:</strong> {{ $provider?->business_name ?? 'No disponible' }}</p>
            <p><strong>Experiencia:</strong> {{ $booking?->experience?->title ?? 'Experiencia AndanDO' }}</p>
            <p><strong>Código de reserva:</strong> #{{ $booking?->booking_code }}</p>
            <p><strong>Motivo:</strong> {{ $claim->reason }}</p>
            <p><strong>Descripción:</strong> {{ $claim->description ?: 'Sin descripción adicional' }}</p>
            <p><strong>Estado:</strong> Pendiente</p>
            <p><strong>Fecha:</strong> {{ $claim->created_at?->format('d/m/Y h:i A') }}</p>
        </td>
    </tr>
</table>

<p style="font-size:16px; line-height:1.7;">
    Ingresa al panel administrativo para revisar el reclamo y darle seguimiento.
</p>

@endsection