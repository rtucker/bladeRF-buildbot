bladeRF-buildbot
================

Continuous build system for nuand bladeRF components

Usage
=====

This is a work in progress!!

1. `cd docker-quartus` and `./do_build`
2. Wait for it to download and install ~10 GB of Quartus Prime
3. Check out the bladeRF repository somewhere and cd to the base of it (`git clone https://github.com/Nuand/bladeRF.git && cd bladeRF`)
4. `docker run --rm -i -t -v /sys:/sys:ro -v $(pwd):/build quartus-lite`
5. You will find yourself in the `Altera Nios2 Command Shell`
6. `cd /build/hdl/quartus`
7. `./build_bladerf.sh -c -b bladeRF -r hosted -s 115` (or other arguments as desired)

To-do
=====

- Migrate this to use Docker Swarm and secret storage
- Actually automate
