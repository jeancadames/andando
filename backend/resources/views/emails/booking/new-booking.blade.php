@extends('emails.layouts.app')

@section('content')

<h1 style="font-size:36px; line-height:1.1; color:#003b88; margin:0 0 16px;">
    Tienes una <span style="color:#ef233c;">nueva reserva</span> 🔔
</h1>

<p style="font-size:16px; line-height:1.6; margin:0 0 28px;">
    Hola, <strong>{{ $providerUser->name }}</strong>.<br>
    Un cliente acaba de reservar una de tus experiencias en AndanDO.
</p>

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
                <strong>Cliente:</strong> {{ $booking->customer_name }}
            </p>

            <p style="margin:0 0 8px;">
                <strong>Teléfono:</strong> {{ $booking->customer_phone ?? 'No disponible' }}
            </p>

            <p style="margin:0 0 8px;">
                <strong>Correo:</strong> {{ $booking->customer_email ?? 'No disponible' }}
            </p>

            <p style="margin:0 0 8px;">
                <strong>Fecha:</strong> {{ $booking->booking_date?->format('d/m/Y h:i A') }}
            </p>

            <p style="margin:0 0 8px;">
                <strong>Personas:</strong> {{ $booking->guests_count }}
            </p>

            <p style="margin:0 0 8px;">
                <strong>Punto de recogida:</strong> {{ $booking->pickup_point ?? 'No aplica' }}
            </p>

            <p style="margin:0;">
                <strong>Monto total:</strong> RD$ {{ number_format((float) $booking->total_amount, 2) }}
            </p>
        </td>
    </tr>
</table>

<table width="100%" cellpadding="0" cellspacing="0" style="background:#f1f6ff; border-radius:16px; margin-bottom:28px;">
    <tr>
        <td style="padding:24px;">
            <h3 style="color:#003b88; margin:0 0 16px;">Próximos pasos</h3>

            <p style="margin:0 0 8px;">✓ Revisa los detalles de la reserva.</p>
            <p style="margin:0 0 8px;">✓ Prepara la experiencia para la fecha indicada.</p>
            <p style="margin:0 0 8px;">✓ Mantente atento al chat del cliente.</p>
            <p style="margin:0;">✓ Contacta a soporte si notas algún inconveniente.</p>
        </td>
    </tr>
</table>

<div style="text-align:center;">
    <a href="{{ $actionUrl ?? '#' }}"
       style="background:#ef233c; color:#ffffff; padding:14px 34px; border-radius:8px; text-decoration:none; font-weight:bold; display:inline-block;">
        Ver reserva
    </a>
</div>

@endsection