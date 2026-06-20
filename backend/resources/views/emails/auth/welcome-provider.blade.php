@extends('emails.layouts.app')

@section('content')

<h1 style="font-size:36px; color:#003b88; margin-bottom:16px;">
    ¡Solicitud recibida! 🎉
</h1>

<p style="font-size:16px; line-height:1.7;">
    Hola <strong>{{ $user->name }}</strong>,
</p>

<p style="font-size:16px; line-height:1.7;">
    Gracias por registrarte como afiliado en AndanDO.
</p>

<p style="font-size:16px; line-height:1.7;">
    Hemos recibido tu solicitud y nuestro equipo revisará la información y los documentos enviados.
</p>

<table width="100%" cellpadding="0" cellspacing="0"
       style="background:#f1f6ff; border-radius:16px; margin:30px 0;">
    <tr>
        <td style="padding:24px;">
            <h3 style="color:#003b88; margin-top:0;">
                Resumen de tu solicitud
            </h3>

            <p><strong>Negocio:</strong> {{ $provider?->business_name ?? 'No especificado' }}</p>
            <p><strong>Estado:</strong> Pendiente de revisión</p>
            <p><strong>Próximo paso:</strong> Esperar aprobación del equipo de AndanDO.</p>
        </td>
    </tr>
</table>

<p style="font-size:16px; line-height:1.7;">
    Te notificaremos por correo cuando tu perfil sea aprobado o si necesitamos información adicional.
</p>

<div style="text-align:center;">
    <a href="#"
       style="background:#ef233c;
              color:white;
              padding:14px 34px;
              text-decoration:none;
              border-radius:8px;
              font-weight:bold;">
        Ver estado de solicitud
    </a>
</div>

@endsection