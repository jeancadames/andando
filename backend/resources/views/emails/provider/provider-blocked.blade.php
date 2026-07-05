@extends('emails.layouts.app')

@section('content')
    <h1 style="margin:0 0 16px; color:#003b88;">Cuenta de afiliado suspendida</h1>

    <p style="font-size:16px; line-height:1.6;">
        Hola {{ $provider->user->name ?? 'afiliado' }},
    </p>

    <p style="font-size:16px; line-height:1.6;">
        Tu cuenta de proveedor en AndanDO ha sido suspendida.
    </p>

    <p style="font-size:16px; line-height:1.6;">
        Mientras la suspensión esté activa, no podrás operar experiencias ni recibir nuevas reservas.
    </p>

    <p style="font-size:14px; line-height:1.6; color:#475569;">
        Si entiendes que esto fue un error o necesitas más información, contacta al equipo de soporte.
    </p>
@endsection