#!/usr/bin/perl

#This script gets the graphs from Zenoss monitoring and sends they to user email

use LWP;
use HTTP::Cookies;
use LWP::Simple;
use strict;
use MIME::Lite;
use MIME::Base64;

my $browser = LWP::UserAgent->new;
#$browser->cookie_jar(HTTP::Cookies->new(file => "d:\\programming\\perl\\lwpcookies.txt",autosave => 1));
my $file1 = "/opt/zenoss/scripts/sendReport/graph1.png";
my $file2 = "/opt/zenoss/scripts/sendReport/graph2.png";
my $url1 = "http://192.168.14.1:8080/zport/RenderServer/render?width=500&gopts=eNq1kF1LwzAUhn_M2GWadEydB3oRtmwKm0jsxIuCZNnp1pl9kKTdkPx4WxD0plUvPDeH8_G-PLxkGogIhGyx2Gx9EjNWDxVaX2hliFErNMkYjStKF-7kci5gyHoj1hQs1CXF_Qmt8qXFbBcmYgorRH_Gg1T6zX27EqvOCT2ePH3Hw9E5Wh9yOsGq0OhofDuI4utRNIziG9ri8Nqyj6xdw9ox4M9C8pn4iYLs1eWfSRb8JYw7MJIOvMCl4F38Pca0ZizP257C7FHeP6RdHjDnTyno0mbQv4oGJu-736g-EwZVbf4kbCJvQoG6fwmz3QfeCOZG&drange=129600";
my $url2 = "http://192.168.14.1:8080/zport/RenderServer/render?width=500&gopts=eNq1kEtrwkAUhX-MuJxHQi06kMWgoy1oKdO0dBEo43ijseODmUmUMj--CQjtJtEuejeX-ziHj4OmAYmA0AaK9cYnEaX1UIH1hVYGGbUEk4zBuKJ04UG-zgWLB70hbYot1DmF3RGs8qWFbBsmYsqWAP4Ee6n0p_t1RVadEnI4evIF-4NzpD7kZAJVocGRaBTj6H6I73A0Ii0OHy17bO2KrRxl_E1IPhPXKNBOnf-ZZMHfw7gDI-nAC1wK3sXfo1RrSvO87SnMnuXjU9rlweb8JWW6tBnrD3Bs8r67RXVJmKlq_SdhE3kTCqv7jzDbfgPrgOZN&drange=129600";
my $response1 = $browser->post( $url1,
    [ '__ac_name' => 'admin',
    	'__ac_password' => 'password',
    	'submit' => 'submitbutton'
    ]);

my $response2 = $browser->post( $url2,
    [ '__ac_name' => 'admin',
    	'__ac_password' => 'password',
    	'submit' => 'submitbutton'
    ]);


binmode STDOUT,':raw';

open (STDOUT, ">", $file1);
print ($response1 -> content);

open (STDOUT, ">", $file2);
print ($response2 -> content);
close STDOUT;

my $msg = MIME::Lite -> new( 
            From        =>  'monitoring@ntzmk.ru',
            To          =>  'someuser@somedomain.ru',
            Type	=>  'multipart/related',
            Encoding	=>  '8bit',
            Subject     =>  'Температура в серверной'
#            Data	=>	''
 ); 

$msg -> attach( 
		Type	=>	'text/html',
		Data	=>	qq{
				<html><body><h3>Графики изменения температуры на серверных стойках</h3><br><h4>Фронтальная сторона стоек</h4><img src="cid:graph2.png" alt=""/><br><h4>Тыльная сторона стоек</h4><img src="cid:graph1.png" alt=""/></body></html>
				},
				);
$msg->attach(  Type        =>  'image/png',
                Path        =>  '/opt/zenoss/scripts/sendReport/graph2.png',
                Filename    =>  'graph2.png',
                Disposition =>  'attachment'
 );

 
 $msg->attach(  Type        =>  'image/png',
                Path        =>  '/opt/zenoss/scripts/sendReport/graph1.png',
                Filename    =>  'graph1.png',
                Disposition =>  'attachment'
 ); 
 $msg->send('smtp', '192.168.4.1'); 
