<?php
require 'vendor/autoload.php';

use \Aws\Sqs;

$sqsCredentials = array(
        'region' => 'ap-northeast-1',
        'version' => 'latest'
);
$sqs = Sqs\SqsClient::factory($sqsCredentials);
$queue_url = 'https://sqs.ap-northeast-1.amazonaws.com/XXXXXXXXXXXXX/testsqs';

while(true){
echo date(DATE_ATOM);
echo ("\n");
$sqs->sendMessage(array(
      'QueueUrl'    => $queue_url,
      'MessageBody' => 'An awesome !'.date("H:i:s"),
));
sleep(20);
}
?>
