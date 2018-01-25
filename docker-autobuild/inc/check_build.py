#!/usr/bin/env python3

# bladeRF autobuild bot: build status checker
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
import sys

logging.basicConfig(level=logging.INFO)
logging.getLogger('boto3').setLevel(logging.WARNING)

def poll(queue, build_id):
    THROWBACK_TIME=25

    logger = logging.getLogger("check_build.poll")

    while True:
        msg = queue_mgr.get_message(queue,
            worker_types=['ping-response', 'worker-fpga-quartus-response'])

        if msg is None:
            break

        workertype = msg.message_attributes['WorkerType']['StringValue']

        logger.info("MessageId=%s, WorkerType=%s", msg.message_id, workertype)

        my_id = queue_mgr.get_build_id(msg.body)
        delete = False
        result = None

        logger.info("Found %s message with build_id=%s", workertype, my_id)

        if workertype == "ping-response":
            logger.info("Found ping response!")
            logger.info("Body: %s", msg.body)
            delete = True

        if my_id == build_id:
            logger.info("Found a match!")
            logger.info("Body: %s", msg.body)
            delete = True
            result = queue_mgr.get_result_code(msg.body)

        if my_id is None:
            delete = True

        if delete:
            logger.info("Deleting: %s (%s)", msg.message_id, workertype)
            msg.delete()

            if result is not None:
                return result

            continue

        msg.change_visibility(VisibilityTimeout=THROWBACK_TIME)

    return None

def main():
    logger = logging.getLogger("check_build")

    if len(sys.argv) < 3:
        sys.stderr.write("Usage: %s <queue_name> <build_id>\n" % (sys.argv[0],))
        return 1

    queuename = sys.argv[1]
    build_id = sys.argv[2]

    queue = queue_mgr.get_queue(queuename)

    result = poll(queue, build_id)

    if result is not None:
        print("OK (%s)" % result)
        sys.exit(0)
    else:
        print("NOTFOUND")
        sys.exit(1)

if __name__ == "__main__":
    main()
