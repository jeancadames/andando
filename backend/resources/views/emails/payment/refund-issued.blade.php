@extends('emails.layouts.app')

@section('content')
    <h1 style="margin:0 0 16px; color:#003b88;">Reembolso procesado</h1>

    <p style="font-size:16px; line-height:1.6;">
        Hola {{ $booking->user->name ?? 'cliente' }},
    </p>

    <p style="font-size:16px; line-height:1.6;">
        Hemos procesado un reembolso relacionado con tu reserva.
    </p>

    <p style="font-size:16px; line-height:1.6;">
        <strong>Experiencia:</strong> {{ $booking->experience->title ?? 'Experiencia reservada' }}<br>
        <strong>Monto reembolsado:</strong> {{ $amount ?? 'N/D' }}
    </p>

    <p style="font-size:14px; line-height:1.6; color:#475569;">
        El tiempo de acreditación puede variar según tu banco o entidad emisora.
    </p>
@endsection