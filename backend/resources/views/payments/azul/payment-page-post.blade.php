<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Redirigiendo a Azul...</title>
</head>
<body>
    <p>Redirigiendo a la página segura de Azul...</p>

    <form id="azul-payment-page-form" method="POST" action="{{ $paymentPageUrl }}">
        @foreach ($fields as $name => $value)
            <input type="hidden" name="{{ $name }}" value="{{ $value }}">
        @endforeach
    </form>

    <script>
        document.getElementById('azul-payment-page-form').submit();
    </script>
</body>
</html>