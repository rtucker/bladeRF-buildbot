#!/usr/bin/env python3

# bladeRF autobuild bot: build queuer
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

def build_message_fpga(build_id, commit_id, fpga_rev, fpga_size):
    return {
        'host': queue_mgr.node_info(),
        'task': {
            'build_id': build_id,
            'commit_id': commit_id,
            'fpga_revision': fpga_rev,
            'fpga_size': fpga_size,
        }
    }

def main():
    logger = logging.getLogger("enqueue_build")

    if len(sys.argv) < 6:
        sys.stderr.write("Usage: %s <queue_name> <build_id> <commit id> <fpga revision> <fpga size>\n" % (sys.argv[0],))
        return 1

    queuename = sys.argv[1]
    build_id = sys.argv[2]
    commit_id = sys.argv[3]
    fpga_rev = sys.argv[4]
    fpga_size = sys.argv[5]

    queue = queue_mgr.get_queue(queuename)

    msg = build_message_fpga(build_id, commit_id, fpga_rev, fpga_size)

    queue_mgr.send_message(queue, "worker-fpga-quartus", msg)

if __name__ == "__main__":
    main()
