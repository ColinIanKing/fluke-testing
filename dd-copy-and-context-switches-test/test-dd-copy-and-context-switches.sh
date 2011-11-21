#!/bin/bash
dd if=/dev/zero bs=1M count=2048 | cat | cat | dd of=/dev/zero
