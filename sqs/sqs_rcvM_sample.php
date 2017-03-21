<?php
require 'vendor/autoload.php';

use \Aws\Sqs;

$sqsCredentials = array(
        'region' => 'ap-northeast-1',
        'version' => 'latest'
);
$sqs = Sqs\SqsClient::factory($sqsCredentials);
$queue_url = 'https://sqs.ap-northeast-1.amazonaws.com/XXXXXXXXXX/testsqs';

        while (true) {
                echo date(DATE_ATOM);
                echo ("\n");
                $receiveOption = array(
                        'WaitTimeSeconds'   => 20,
                        'QueueUrl'          => $queue_url,
                        'VisibilityTimeout' => 60,
                );
                $message = $sqs->receiveMessage($receiveOption);

                usleep(rand(1000,6000000));
                // deal with message
                if(!empty($message->getPath('Messages'))){
                        $sqs->deleteMessage(array(
                                'QueueUrl'      => $queue_url,
                                'ReceiptHandle' => $message['Messages'][0]['ReceiptHandle'],
                        ));
                }
        }
?>
