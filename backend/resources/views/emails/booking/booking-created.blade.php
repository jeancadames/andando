@extends('emails.layouts.app')

@section('content')

<h1 style="font-size:36px; line-height:1.1; color:#003b88; margin:0 0 16px;">
    ¡Tu reserva está <span style="color:#ef233c;">confirmada!</span> 🎉
</h1>

<p style="font-size:16px; line-height:1.6; margin:0 0 28px;">
    Hola, <strong>{{ $booking->customer_name }}</strong>.<br>
    Gracias por reservar con AndanDO. Estamos emocionados de que vivas esta experiencia única.
</p>

<table width="100%" cellpadding="0" cellspacing="0" style="border:1px solid #e5e7eb; border-radius:16px; margin-bottom:28px;">
    <tr>
        <td style="padding:28px;">
            <h2 style="color:#003b88; margin:0 0 22px; font-size:22px;">
                Resumen de tu reserva
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

            <p style="margin:0 0 8px;">
                <strong>Punto de encuentro:</strong> {{ $booking->pickup_point ?? 'Por confirmar' }}
            </p>

            <p style="margin:0;">
                <strong>Total pagado:</strong> RD$ {{ number_format((float) $booking->total_amount, 2) }}
            </p>
        </td>
    </tr>
</table>

<table width="100%" cellpadding="0" cellspacing="0" style="background:#f1f6ff; border-radius:16px; margin-bottom:28px;">
    <tr>
        <td style="padding:24px;">
            <h3 style="color:#003b88; margin:0 0 16px;">Información importante</h3>

            <p style="margin:0 0 8px;">✓ Llega 30 minutos antes al punto de encuentro.</p>
            <p style="margin:0 0 8px;">✓ Usa ropa cómoda y zapatos adecuados.</p>
            <p style="margin:0 0 8px;">✓ No olvides protector solar, repelente y una cámara.</p>
            <p style="margin:0;">✓ Revisa la política de cancelación de tu reserva.</p>
        </td>
    </tr>
</table>

<div style="text-align:center;">
    <p style="font-weight:bold; margin-bottom:18px;">
        Puedes ver los detalles completos de tu reserva en la app.
    </p>

    <a href="{{ $actionUrl ?? '#' }}"
       style="background:#ef233c; color:#ffffff; padding:14px 34px; border-radius:8px; text-decoration:none; font-weight:bold; display:inline-block;">
        Ver mi reserva
    </a>
</div>

@endsection