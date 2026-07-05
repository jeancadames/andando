@extends('emails.layouts.app')

@section('content')
    <h1 style="margin:0 0 16px; color:#003b88;">Pago confirmado</h1>

    <p style="font-size:16px; line-height:1.6;">
        Hola {{ $booking->user->name ?? 'cliente' }},
    </p>

    <p style="font-size:16px; line-height:1.6;">
        Hemos confirmado el pago de tu reserva en AndanDO.
    </p>

    <p style="font-size:16px; line-height:1.6;">
        <strong>Experiencia:</strong> {{ $booking->experience->title ?? 'Experiencia reservada' }}<br>
        <strong>Monto:</strong> {{ $amount ?? 'N/D' }}
    </p>

    <p style="font-size:14px; line-height:1.6; color:#475569;">
        Conserva este correo como comprobante de tu pago.
    </p>
@endsection