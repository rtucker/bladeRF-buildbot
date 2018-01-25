#!/usr/bin/env python3

# bladeRF autobuild bot: FPGA build worker
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

import boto3
import json
import logging
import os
import subprocess
import sys
import time

logging.basicConfig(level=logging.INFO)
logging.getLogger('boto3').setLevel(logging.WARNING)

def get_queue(queuename):
    logger = logging.getLogger("worker.get_queue")

    sqs = boto3.resource('sqs')
    queue = sqs.get_queue_by_name(QueueName=queuename)

    logger.debug("Got queue: %s", queue)

    return queue

def execute(body, timeout=None):
    logger = logging.getLogger("worker.execute")

    data = json.loads(body)

    cmd = [
            os.environ['BUILDCOMMAND'],
            data['build_id'],
            data['commit_id'],
            data['fpga_revision'],
            data['fpga_size'],
          ]

    logger.info("Request parsed: %s", data)
    logger.info("Command: %s", cmd)

    r = subprocess.run( cmd,
                        stdout=subprocess.PIPE,
                        stderr=subprocess.PIPE,
                        timeout=timeout )

    return (r.returncode, r.stdout, r.stderr)

def send_message(queue, workertype, contents):
    logger = logging.getLogger("worker.send_message")

    logger.info("Message: %s", contents)

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
    mach = os.uname()

    return  {
                'machine': mach.machine,
                'nodename': mach.nodename,
                'release': mach.release,
                'sysname': mach.sysname,
                'version': mach.version,
            }

def poll(queue):
    WAIT_TIME_SECONDS=20
    THROWBACK_TIME=60
    BUILD_TIME=3600

    logger = logging.getLogger("worker.poll")

    for message in queue.receive_messages(
        MessageAttributeNames=['WorkerType'],
        MaxNumberOfMessages=1,
        WaitTimeSeconds=WAIT_TIME_SECONDS,
    ):
        if message.message_attributes is None:
            logger.warning("message did not have attributes, deleting: %s",
                message)
            message.delete()
            continue

        workertype = message.message_attributes['WorkerType']['StringValue']

        logger.debug("MessageId=%s, WorkerType=%s, body=%s",
                     message.message_id, workertype, message.body)

        start_time = time.time()
        executed = False

        if workertype == 'worker-fpga-quartus':
            logger.info("Executing: %s (%s)", message.message_id, workertype)

            message.change_visibility(VisibilityTimeout=BUILD_TIME)

            try:
                result = execute(message.body, timeout=BUILD_TIME-60)
                end_time = time.time()
                executed = True

            except:
                logging.exception("Exception: %s (%s)",
                                  message.message_id, workertype)

        elif workertype == 'ping':
            logger.info("Executing: %s (%s)", message.message_id, workertype)

            end_time = time.time()
            result = [0, "", ""]
            executed = True

        elif workertype == 'ping-response':
            logger.info("Response: %s (%s)", message.message_id, message.body)
            message.delete()
            #message.change_visibility(VisibilityTimeout=THROWBACK_TIME)

        else:
            logger.debug("Throwing back: %s (%s)", message.message_id, workertype)
            message.change_visibility(VisibilityTimeout=THROWBACK_TIME)

        if executed:
            logger.info("Completed: %s (%s)", message.message_id, workertype)

            msg = {
                'host': node_info(),
                'request': {
                    'message_id': message.message_id,
                    'body': message.body
                },
                'returncode': result[0],
                'stdout': result[1].decode('utf-8'),
                'stderr': result[2].decode('utf-8'),
                'start_time': start_time,
                'end_time': end_time,
                'duration': end_time - start_time,
            }

            try:
                send_message(queue, workertype + "-response", msg)
            except:
                logger.exception("send_message failed")

            logger.info("Deleting: %s (%s)", message.message_id, workertype)
            message.delete()

def main():
    logger = logging.getLogger("worker")

    if len(sys.argv) < 2:
        sys.stderr.write("Usage: %s <queue_name>" % (sys.argv[0],))
        return 1

    for key in ['BUILDCOMMAND', 'WORKDIR', 'BINDIR']:
        if key not in os.environ:
            sys.stderr.write("Missing environment variable: %s" % key)
            return 1

    queuename = sys.argv[1]

    queue = get_queue(queuename)

    while True:
        logger.debug("Polling...")
        poll(queue)

if __name__ == "__main__":
    main()
