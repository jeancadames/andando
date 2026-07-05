@extends('emails.layouts.app')

@section('content')

@php
    $experienceName = $booking->experience?->title ?? 'Experiencia AndanDO';
    $customerName = $booking->customer_name ?: ($booking->user?->name ?? 'Cliente');
    $cancelledByLabel = $cancelledBy === \App\Models\ProviderBooking::CANCELLED_BY_ADMIN
        ? 'administración'
        : 'el afiliado';

    $refundAmount = (float) ($booking->refund_amount ?? 0);
    $refundPercentage = (int) ($booking->refund_percentage ?? 0);
@endphp

<h1 style="font-size:36px; line-height:1.1; color:#003b88; margin:0 0 16px;">
    Tu salida fue <span style="color:#ef233c;">cancelada</span>
</h1>

<p style="font-size:16px; line-height:1.6; margin:0 0 28px;">
    Hola, <strong>{{ $customerName }}</strong>.<br>
    Te informamos que la salida de <strong>{{ $experienceName }}</strong> fue cancelada por {{ $cancelledByLabel }}.
</p>

<table width="100%" cellpadding="0" cellspacing="0" style="border:1px solid #e5e7eb; border-radius:16px; margin-bottom:28px;">
    <tr>
        <td style="padding:28px;">
            <h2 style="color:#003b88; margin:0 0 22px; font-size:22px;">
                Detalles de la reserva afectada
            </h2>

            <p style="margin:0 0 8px;">
                <strong>Experiencia:</strong> {{ $experienceName }}
            </p>

            <p style="margin:0 0 8px;">
                <strong>Código de reserva:</strong> #{{ $booking->booking_code }}
            </p>

            <p style="margin:0 0 8px;">
                <strong>Fecha de la salida:</strong> {{ $booking->booking_date?->format('d/m/Y h:i A') }}
            </p>

            <p style="margin:0 0 8px;">
                <strong>Personas:</strong> {{ $booking->guests_count }}
            </p>

            <p style="margin:0 0 8px;">
                <strong>Total pagado:</strong> RD$ {{ number_format((float) $booking->total_amount, 2) }}
            </p>

            <p style="margin:0 0 8px;">
                <strong>Reembolso:</strong> RD$ {{ number_format($refundAmount, 2) }}
            </p>

            <p style="margin:0;">
                <strong>Porcentaje de reembolso:</strong> {{ $refundPercentage }}%
            </p>
        </td>
    </tr>
</table>

<table width="100%" cellpadding="0" cellspacing="0" style="background:#f1f6ff; border-radius:16px; margin-bottom:28px;">
    <tr>
        <td style="padding:24px;">
            <h3 style="color:#003b88; margin:0 0 16px;">Información importante</h3>

            <p style="margin:0 0 8px;">✓ Tu reserva ya figura como cancelada.</p>
            <p style="margin:0 0 8px;">✓ Al tratarse de una cancelación por afiliado o administración, recibirás el reembolso correspondiente al 100%.</p>
            <p style="margin:0;">✓ El tiempo de acreditación puede variar según el método de pago y la entidad bancaria.</p>
        </td>
    </tr>
</table>

<div style="text-align:center;">
    <a href="{{ $actionUrl ?? '#' }}"
       style="background:#ef233c; color:#ffffff; padding:14px 34px; border-radius:8px; text-decoration:none; font-weight:bold; display:inline-block;">
        Ver detalles
    </a>
</div>

@endsection