@extends('emails.layouts.app')

@section('content')

@if ($recipientType === 'provider')
    <h1 style="font-size:36px; line-height:1.1; color:#003b88; margin:0 0 16px;">
        Un cliente canceló una <span style="color:#ef233c;">reserva</span>
    </h1>

    <p style="font-size:16px; line-height:1.6; margin:0 0 28px;">
        Hola, <strong>{{ $booking->provider?->user?->name ?? 'Afiliado' }}</strong>.<br>
        Un cliente canceló una reserva asociada a tu experiencia.
    </p>
@else
    <h1 style="font-size:36px; line-height:1.1; color:#003b88; margin:0 0 16px;">
        Tu reserva fue <span style="color:#ef233c;">cancelada</span>
    </h1>

    <p style="font-size:16px; line-height:1.6; margin:0 0 28px;">
        Hola, <strong>{{ $booking->customer_name }}</strong>.<br>
        Hemos procesado la cancelación de tu reserva.
    </p>
@endif

<table width="100%" cellpadding="0" cellspacing="0" style="border:1px solid #e5e7eb; border-radius:16px; margin-bottom:28px;">
    <tr>
        <td style="padding:28px;">
            <h2 style="color:#003b88; margin:0 0 22px; font-size:22px;">
                Detalles de la reserva
            </h2>

            <p style="margin:0 0 8px;">
                <strong>Experiencia:</strong> {{ $booking->experience?->title ?? 'Experiencia AndanDO' }}
            </p>

            <p style="margin:0 0 8px;">
                <strong>Código:</strong> #{{ $booking->booking_code }}
            </p>

            <p style="margin:0 0 8px;">
                <strong>Fecha:</strong> {{ $booking->booking_date?->format('d/m/Y h:i A') }}
            </p>

            <p style="margin:0 0 8px;">
                <strong>Personas:</strong> {{ $booking->guests_count }}
            </p>

            @if ($recipientType === 'provider')
                <p style="margin:0 0 8px;">
                    <strong>Cliente:</strong> {{ $booking->customer_name }}
                </p>

                <p style="margin:0 0 8px;">
                    <strong>Correo:</strong> {{ $booking->customer_email ?? 'No disponible' }}
                </p>
            @endif

            <p style="margin:0 0 8px;">
                <strong>Total de la reserva:</strong> RD$ {{ number_format((float) $booking->total_amount, 2) }}
            </p>

            <p style="margin:0 0 8px;">
                <strong>Reembolso estimado:</strong> RD$ {{ number_format((float) $booking->refund_amount, 2) }}
            </p>

            <p style="margin:0;">
                <strong>Porcentaje de reembolso:</strong> {{ (int) $booking->refund_percentage }}%
            </p>
        </td>
    </tr>
</table>

<table width="100%" cellpadding="0" cellspacing="0" style="background:#f1f6ff; border-radius:16px; margin-bottom:28px;">
    <tr>
        <td style="padding:24px;">
            @if ($recipientType === 'provider')
                <h3 style="color:#003b88; margin:0 0 16px;">Qué significa esto</h3>

                <p style="margin:0 0 8px;">✓ Los cupos de esta reserva quedan liberados.</p>
                <p style="margin:0 0 8px;">✓ No necesitas contactar al cliente por esta cancelación.</p>
                <p style="margin:0;">✓ AndanDO gestionará el proceso correspondiente.</p>
            @else
                <h3 style="color:#003b88; margin:0 0 16px;">Información importante</h3>

                <p style="margin:0 0 8px;">✓ Tu reserva ya figura como cancelada.</p>
                <p style="margin:0 0 8px;">✓ Si aplica reembolso, será procesado según la política de cancelación.</p>
                <p style="margin:0;">✓ El tiempo de acreditación puede variar según el método de pago.</p>
            @endif
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