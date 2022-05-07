<?php

try {
echo 'REQUEST_SCHEME: ', $_SERVER['REQUEST_SCHEME'], '<br>';
echo 'HTTP_X_FORWARDED_PROTO: ', $_SERVER['HTTP_X_FORWARDED_PROTO'], '<br>';
echo 'SERVER_PROTOCOL: ', $_SERVER['SERVER_PROTOCOL'], '<br>';
echo 'HTTPS: ', $_SERVER['HTTPS'], '<br>';
} catch (Exception $e) {
    echo 'Exception: ',  $e->getMessage(), "\n";
 }

phpinfo();
?>