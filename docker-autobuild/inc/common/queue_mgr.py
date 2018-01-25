#!/usr/bin/env python3

# bladeRF autobuild bot: common Python stuff
#
# Copyright (c) 2018 Rey Tucker <bladeRF-buildbot@reytucker.us>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

import json
import logging
import time

logger = logging.getLogger(__name__)

def get_queue(queuename):
    import boto3

    sqs = boto3.resource('sqs')
    queue = sqs.get_queue_by_name(QueueName=queuename)

    logger.debug("Got queue: %s", queue)

    return queue

def decode_fpga_task(body):
    data = json.loads(body)

    return [data['task']['build_id'],
            data['task']['commit_id'],
            data['task']['fpga_revision'],
            data['task']['fpga_size']]

def get_build_id(body):
    data = json.loads(body)

    if 'request' in data and 'build_id' in data['request']:
        return data['request']['build_id']
    elif 'build_id' in data:
        return data['build_id']
    else:
        return None

def get_result_code(body):
    data = json.loads(body)

    if 'result' in data and 'returncode' in data['result']:
        return data['result']['returncode']
    else:
        return None

def send_message(queue, workertype, contents):
    logger.debug("Message: %s", contents)

    response = queue.send_message(
        MessageBody=json.dumps(contents),
        MessageAttributes={
            'WorkerType': {
                'StringValue': workertype,
                'DataType': 'String',
            }
        }
    )

    logger.info("Sent: %s (%s)", response.get('MessageId'), workertype)

def node_info():
    import os

    mach = os.uname()

    return  {
                'machine': mach.machine,
                'nodename': mach.nodename,
                'release': mach.release,
                'sysname': mach.sysname,
                'version': mach.version,
            }

def get_message(queue, worker_types=[], long_poll=True, timeout=10):
    if long_poll:
        WAIT_TIME_SECONDS=min(timeout, 20)
    else:
        WAIT_TIME_SECONDS=0

    THROWBACK_TIME=timeout+5

    start = time.time()

    while time.time() < (start + timeout):
        for msg in queue.receive_messages(
            MessageAttributeNames=['WorkerType'],
            MaxNumberOfMessages=1,
            WaitTimeSeconds=WAIT_TIME_SECONDS,
        ):
            logger.debug("considering: %s", msg)

            if len(worker_types) is None:
                logger.debug("returning: %s", msg)
                return msg

            if msg.message_attributes is None:
                logger.warning("message_attributes is null, deleting: %s", msg)
                msg.delete()
                continue

            workertype = msg.message_attributes['WorkerType']['StringValue']

            if workertype in worker_types:
                logger.debug("returning (match): %s", msg)
                return msg

            logger.debug("throwing back: %s", msg)
            msg.change_visibility(VisibilityTimeout=THROWBACK_TIME)

    return None
