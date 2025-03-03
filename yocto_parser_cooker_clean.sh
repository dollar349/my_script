#!/bin/bash

ps -U $USER | grep -e Cooker -e Parser | awk '{print $1}' | xargs -i kill {}
