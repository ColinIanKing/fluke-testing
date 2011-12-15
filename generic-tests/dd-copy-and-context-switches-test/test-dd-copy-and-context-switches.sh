#!/bin/bash
dd if=/dev/zero bs=1M count=16384 | cat | cat | dd of=/dev/zero
