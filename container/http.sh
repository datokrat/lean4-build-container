#!/bin/bash

tmux new-session -d -s http 'python3 -m http.server -d /static'

