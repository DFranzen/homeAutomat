<?php	
  $ip = "192.168.1.100";
  if (isset($_GET['ip']) ) {
    $ip = $_GET['ip'];
  }
  $input = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n";
  $input .= "<s:Envelope xmlns:s=\"http://schemas.xmlsoap.org/soap/envelope/\" s:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\">\n";
  $input .= "<s:Body>\n";
  $input .= "<u:GetVolume xmlns:u=\"urn:schemas-upnp-org:service:RenderingControl:1\">\n";
  $input .= "<InstanceID>0</InstanceID><Channel>Master</Channel>";
  $input .= "</u:GetVolume>\n";
  $input .= "</s:Body>\n";
  $input .= "</s:Envelope>\n\n";
  $header = array(
    "Content-type: text/xml;charset=\"utf-8\"",
    "Accept: text/xml",
    "Cache-Control: no-cache",
    "Pragma: no-cache",
    "SOAPACTION: \"urn:schemas-upnp-org:service:RenderingControl:1#GetVolume\"",
    "Content-Length: ".strlen($input),
  );
  $curl = curl_init();
  curl_setopt($curl, CURLOPT_URL, 'http://'.$ip.':55000/dmr/control_0');
  curl_setopt($curl, CURLOPT_POST, 1);
  curl_setopt($curl, CURLOPT_HTTPHEADER, $header);
  curl_setopt($curl, CURLOPT_POSTFIELDS, $input);
  curl_setopt($curl, CURLOPT_RETURNTRANSFER, 1);
  $output = curl_exec($curl);
  if($output === false) {
    $err = 'Curl error: ' . curl_error($curl);
    curl_close($curl);
    print $err;
  } else {
    curl_close($curl);
    print $output;
    print 'Operation completed without any errors';
  }
?>
			  
