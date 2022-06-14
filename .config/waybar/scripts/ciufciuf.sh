#!/bin/sh
curl https://d6o.portalefrecce.it/PortaleFrecce/infoViaggioActionJson 2> /dev/null | jq -r '.speed'

