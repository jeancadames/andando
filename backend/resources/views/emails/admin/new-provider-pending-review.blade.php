@extends('emails.layouts.app')

@section('content')

<h1 style="font-size:36px; color:#003b88; margin-bottom:16px;">
    Nuevo afiliado pendiente 📋
</h1>

<p style="font-size:16px; line-height:1.7;">
    Se ha registrado un nuevo afiliado que requiere revisión.
</p>

<table width="100%" cellpadding="0" cellspacing="0"
       style="border:1px solid #e5e7eb; border-radius:16px; margin:30px 0;">
    <tr>
        <td style="padding:24px;">

            <p><strong>Nombre:</strong> {{ $user->name }}</p>

            <p><strong>Email:</strong> {{ $user->email }}</p>

            <p><strong>Negocio:</strong> {{ $provider->business_name }}</p>

            <p><strong>Ciudad:</strong> {{ $provider->city }}</p>

            <p><strong>Provincia:</strong> {{ $provider->province }}</p>

            <p><strong>Fecha:</strong> {{ now()->format('d/m/Y h:i A') }}</p>

        </td>
    </tr>
</table>

<p>
    Ingresa al panel administrativo para revisar la documentación y aprobar o rechazar la solicitud.
</p>

@endsection