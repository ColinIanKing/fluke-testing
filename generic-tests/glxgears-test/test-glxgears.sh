#!/bin/bash
glxgears -fullscreen &
sleep 60
killall -9 glxgears
