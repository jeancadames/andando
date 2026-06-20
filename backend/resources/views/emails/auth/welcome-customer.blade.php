@extends('emails.layouts.app')

@section('content')

<h1 style="font-size:36px; color:#003b88; margin-bottom:16px;">
    ¡Bienvenido a AndanDO! 🎉
</h1>

<p style="font-size:16px; line-height:1.7;">
    Hola <strong>{{ $user->name }}</strong>,
</p>

<p style="font-size:16px; line-height:1.7;">
    Gracias por crear tu cuenta en AndanDO.
</p>

<p style="font-size:16px; line-height:1.7;">
    A partir de ahora podrás descubrir experiencias auténticas,
    reservar actividades y conectar con los mejores anfitriones
    de República Dominicana.
</p>

<table width="100%" cellpadding="0" cellspacing="0"
       style="background:#f1f6ff; border-radius:16px; margin:30px 0;">
    <tr>
        <td style="padding:24px;">
            <h3 style="color:#003b88; margin-top:0;">
                ¿Qué puedes hacer ahora?
            </h3>

            <p>✓ Completar tu perfil.</p>
            <p>✓ Explorar experiencias.</p>
            <p>✓ Guardar favoritos.</p>
            <p>✓ Reservar tu primera aventura.</p>
        </td>
    </tr>
</table>

<div style="text-align:center;">
    <a href="#"
       style="background:#ef233c;
              color:white;
              padding:14px 34px;
              text-decoration:none;
              border-radius:8px;
              font-weight:bold;">
        Explorar experiencias
    </a>
</div>

@endsection