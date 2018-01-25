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

import queue_mgr

import logging
import os
import subprocess
import sys
import time

logging.basicConfig(level=logging.INFO)
logging.getLogger('boto3').setLevel(logging.WARNING)

def execute(arglist, timeout=None):
    logger = logging.getLogger("worker.execute")

    cmd = [os.environ['BUILDCOMMAND']] + arglist

    logger.info("Command: %s", cmd)

    r = subprocess.run( cmd,
                        stdout=subprocess.PIPE,
                        stderr=subprocess.PIPE,
                        timeout=timeout )

    return (r.returncode, r.stdout, r.stderr)

def poll(queue):
    THROWBACK_TIME=15
    BUILD_TIME=3600

    logger = logging.getLogger("worker.poll")

    msg = queue_mgr.get_message(queue,
        worker_types=['ping', 'worker-fpga-quartus'])

    if msg is not None:
        workertype = msg.message_attributes['WorkerType']['StringValue']

        logger.info("MessageId=%s, WorkerType=%s", msg.message_id, workertype)
        logger.debug("MessageId=%s, Body=%s", msg.message_id, msg.body)

        start_time = time.time()
        executed = False

        if workertype == 'worker-fpga-quartus':
            logger.info("Executing: %s (%s)", msg.message_id, workertype)

            msg.change_visibility(VisibilityTimeout=BUILD_TIME)

            try:
                params = queue_mgr.decode_fpga_task(msg.body)
            except:
                logging.exception("Parsing Exception, retrying: %s (%s)",
                                  msg.message_id, workertype)
                msg.change_visibility(VisibilityTimeout=THROWBACK_TIME)
                return True

            try:
                result = execute(params, timeout=BUILD_TIME-60)
                end_time = time.time()
                executed = True
            except:
                logging.exception("Exception: %s (%s)",
                                  msg.message_id, workertype)

        elif workertype == 'ping':
            logger.info("Executing: %s (%s)", msg.message_id, workertype)

            end_time = time.time()
            params = [""]
            result = [0, "", ""]
            executed = True

        else:
            logger.warning("unhandled workertype: %s (%s)", msg.message_id,
                workertype)
            msg.change_visibility(VisibilityTimeout=THROWBACK_TIME)

        if executed:
            logger.info("Completed: %s (%s)", msg.message_id, workertype)

            resp = {
                'host': queue_mgr.node_info(),
                'request': {
                    'build_id': params[0],
                    'message_id': msg.message_id,
                    'body': msg.body
                },
                'result': {
                    'returncode': result[0],
                    'stdout': str(result[1][-4096:]),
                    'stderr': str(result[2][-4096:]),
                    'start_time': start_time,
                    'end_time': end_time,
                    'duration': end_time - start_time,
                }
            }

            try:
                queue_mgr.send_message(queue, workertype + "-response", resp)
                logger.info("Deleting: %s (%s)", msg.message_id, workertype)
                msg.delete()

            except:
                logger.exception("send_message failed")
                msg.change_visibility(VisibilityTimeout=THROWBACK_TIME)

        return True

    else:
        return False

def main():
    logger = logging.getLogger("worker")

    if len(sys.argv) < 2:
        sys.stderr.write("Usage: %s <queue_name>\n" % (sys.argv[0],))
        return 1

    for key in ['BUILDCOMMAND', 'WORKDIR', 'BINDIR']:
        if key not in os.environ:
            sys.stderr.write("Missing environment variable: %s" % key)
            return 1

    queuename = sys.argv[1]

    queue = queue_mgr.get_queue(queuename)

    while True:
        logger.debug("Polling...")
        empty = poll(queue)
        if empty:
            logger.debug("Pausing for 60 seconds...")
            time.sleep(60)

if __name__ == "__main__":
    main()
