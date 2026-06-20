@extends('emails.layouts.app')

@section('content')

<h1 style="font-size:36px; color:#003b88; margin-bottom:16px;">
    Tu aventura comienza mañana 🌴
</h1>

<p style="font-size:16px; line-height:1.7;">
    Hola <strong>{{ $user->name }}</strong>,
</p>

<p style="font-size:16px; line-height:1.7;">
    Queremos recordarte que tu experiencia está programada para las próximas 24 horas.
</p>

<table width="100%" cellpadding="0" cellspacing="0"
       style="border:1px solid #e5e7eb; border-radius:16px; margin:30px 0;">
    <tr>
        <td style="padding:24px;">

            <p><strong>Experiencia:</strong> {{ $booking->experience?->title }}</p>

            <p><strong>Código:</strong> #{{ $booking->booking_code }}</p>

            <p><strong>Fecha:</strong>
                {{ $booking->booking_date?->format('d/m/Y h:i A') }}
            </p>

            <p><strong>Participantes:</strong>
                {{ $booking->guests_count }}
            </p>

            <p><strong>Punto de encuentro:</strong>
                {{ $booking->pickup_point ?? 'Ver detalles en la aplicación' }}
            </p>

        </td>
    </tr>
</table>

<table width="100%" cellpadding="0" cellspacing="0"
       style="background:#f1f6ff; border-radius:16px; margin-bottom:30px;">
    <tr>
        <td style="padding:24px;">

            <h3 style="color:#003b88; margin-top:0;">
                Antes de salir
            </h3>

            <p>✓ Llega al menos 30 minutos antes.</p>
            <p>✓ Lleva batería suficiente en tu teléfono.</p>
            <p>✓ Verifica el clima de la zona.</p>
            <p>✓ Revisa nuevamente los detalles de tu reserva.</p>

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
              font-weight:bold;">
        Ver mi reserva
    </a>
</div>

@endsection